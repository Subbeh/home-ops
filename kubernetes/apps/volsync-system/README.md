# VolSync Backup & Restore System

This directory contains the complete backup and restore infrastructure for persistent volumes in the Kubernetes cluster using VolSync, Kopia, and Ceph storage.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Application Pod                             │
│                   (e.g., sonarr, mealie)                        │
└───────────────────┬─────────────────────────────────────────────┘
                    │ writes to
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│            PersistentVolumeClaim (PVC)                          │
│              Storage: Ceph RBD (ceph-block)                      │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    ▼ (hourly schedule)
┌─────────────────────────────────────────────────────────────────┐
│                  VolSync ReplicationSource                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Create VolumeSnapshot (Ceph CSI)                      │  │
│  │ 2. Mount snapshot to temporary PVC                       │  │
│  │ 3. Run Kopia mover pod to backup data                   │  │
│  │ 4. Store backup in Kopia repository (NFS)               │  │
│  │ 5. Clean up snapshot and temporary resources            │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────┬─────────────────────────────────────────────┘
                    │ backup to
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Kopia Repository (NFS)                          │
│          Location: nas-k8s.int.sbbh.cloud                        │
│           Path: /data/nvme/k8s/volsync.kopia                    │
│                                                                  │
│  Retention Policy:                                              │
│  - Hourly: 24 snapshots                                         │
│  - Daily: 7 snapshots                                           │
│  - Weekly: 4 snapshots                                          │
│  - Monthly: 6 snapshots                                         │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. VolSync System (`./volsync/`)

**Purpose:** Manages the backup and restore operations for PersistentVolumes

**Key Resources:**
- **Namespace:** `volsync-system`
- **HelmRelease:** Deploys VolSync operator
- **Dependencies:**
  - `openebs` (for cache storage)
  - `snapshot-controller` (for VolumeSnapshot support)

**Maintenance Jobs:** (`./volsync/maintenance/`)
- Periodic cleanup of stale snapshots and failed backup resources

### 2. Kopia Server (`./kopia/`)

**Purpose:** Provides a centralized backup repository and web UI for managing backups

**Key Features:**
- Web UI available at: `https://kopia.sbbh.cloud`
- Repository type: Filesystem (NFS backend)
- Storage location: NFS share at `nas-k8s.int.sbbh.cloud:/data/nvme/k8s/volsync.kopia`
- Encryption: AES-256 with password stored in Vault

**Configuration:**
- Image: `ghcr.io/home-operations/kopia:0.21.1`
- Repository format: Kopia filesystem repository
- Hostname: `volsync.volsync-system.svc.cluster.local`
- Username: `volsync`

### 3. VolSync Component Templates (`../../components/volsync/`)

Reusable Kustomize components for applications requiring backup:

#### `replicationsource.yaml`
Defines backup source configuration:
- **Schedule:** Hourly at minute 0 (`0 * * * *`)
- **Copy Method:** Snapshot (uses Ceph VolumeSnapshots)
- **Cache Storage:** OpenEBS hostpath (5Gi)
- **Compression:** zstd-fastest
- **Parallelism:** 2 threads for faster backups

#### `replicationdestination.yaml`
Defines restore destination configuration:
- **Trigger:** Manual (`restore-once`)
- **Source Identity:** Links to backup source by name
- **Cleanup:** Automatically removes temp PVCs and cache after restore

#### `pvc.yaml`
PVC template that uses ReplicationDestination as data source for restores

#### `externalsecret.yaml`
Retrieves Kopia repository credentials from Vault (`ops/infra/kopia`)

## Backup Lifecycle

### Automated Hourly Backups

1. **Schedule Trigger** (Every hour at minute 0)
   ```
   Cron: 0 * * * *
   ```

2. **VolumeSnapshot Creation**
   - VolSync requests Ceph CSI to create a VolumeSnapshot
   - Snapshot name: `volsync-<app>-src`
   - Snapshot class: `csi-ceph-blockpool`
   - The snapshot is a point-in-time copy stored in Ceph

3. **Mover Pod Initialization**
   - VolSync creates a temporary "mover" pod
   - Pod mounts the VolumeSnapshot via a temporary PVC
   - Pod has access to Kopia repository credentials from Secret

4. **Kopia Backup Execution**
   - Mover pod runs `kopia snapshot create`
   - Data is read from the mounted snapshot
   - Compression applied (zstd-fastest)
   - Encrypted backup written to NFS repository
   - Metadata stored in Kopia's content-addressable storage

5. **Retention Policy Application**
   - Kopia applies retention rules:
     - Keep 24 hourly snapshots
     - Keep 7 daily snapshots
     - Keep 4 weekly snapshots
     - Keep 6 monthly snapshots
   - Old snapshots beyond retention are marked for deletion

6. **Cleanup**
   - Temporary mover pod is deleted
   - Temporary PVC is deleted
   - VolumeSnapshot is deleted
   - Cache PVC is retained for next backup cycle

7. **Status Update**
   ```yaml
   status:
     lastSyncTime: "2025-11-10T05:42:35Z"
     lastSyncDuration: "3h42m35.703733002s"
     nextSyncTime: "2025-11-10T06:00:00Z"
   ```

### Monitoring Backup Status

Check all ReplicationSources:
```bash
kubectl get replicationsource -A
```

Check specific application backup:
```bash
kubectl describe replicationsource <app-name> -n <namespace>
```

View backup logs:
```bash
kubectl logs -n <namespace> -l volsync.backube/ownedby=<app-name> --tail=100
```

## Restore Lifecycle

### Scenario 1: Restore to New PVC (Disaster Recovery)

This is the standard recovery procedure when an application's data is lost or corrupted.

1. **Prepare Application**
   ```bash
   # Scale down the application to prevent it from using the PVC
   kubectl scale deployment <app-name> -n <namespace> --replicas=0

   # Delete the existing PVC (if it exists and is corrupt)
   kubectl delete pvc <app-name> -n <namespace>
   ```

2. **Add VolSync Component to Application**

   In the application's `kustomization.yaml`:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   components:
     - ../../../../components/volsync
   ```

3. **Set Required Variables**

   In the application's Flux Kustomization (ks.yaml):
   ```yaml
   postBuild:
     substitute:
       APP: <app-name>
       VOLSYNC_CAPACITY: "5Gi"  # Match original PVC size
       VOLSYNC_STORAGECLASS: "ceph-block"
       VOLSYNC_PUID: "1000"
       VOLSYNC_PGID: "1000"
   ```

4. **Trigger Restore**

   The ReplicationDestination is created with trigger set to `restore-once`.
   To trigger a restore, update the trigger value:

   ```bash
   # Edit the ReplicationDestination
   kubectl edit replicationdestination <app-name>-dst -n <namespace>

   # Change:
   spec:
     trigger:
       manual: restore-once

   # To a new value (any different string):
   spec:
     trigger:
       manual: restore-$(date +%Y%m%d%H%M%S)
   ```

5. **Monitor Restore Progress**
   ```bash
   # Check ReplicationDestination status
   kubectl describe replicationdestination <app-name>-dst -n <namespace>

   # Watch restore pod logs
   kubectl logs -n <namespace> -l volsync.backube/ownedby=<app-name>-dst -f
   ```

6. **Create PVC from Restore**

   Once restore is complete, create the PVC using the ReplicationDestination:
   ```bash
   # This happens automatically via the component's pvc.yaml
   # The PVC is created with dataSourceRef pointing to the ReplicationDestination
   kubectl get pvc <app-name> -n <namespace>
   ```

7. **Scale Application Back Up**
   ```bash
   # Restore the application deployment
   kubectl scale deployment <app-name> -n <namespace> --replicas=1

   # Verify application is running with restored data
   kubectl get pods -n <namespace> -l app.kubernetes.io/name=<app-name>
   ```

### Scenario 2: Browse/Extract Specific Files

Use the Kopia web UI to browse snapshots and extract specific files.

1. **Access Kopia UI**
   ```
   URL: https://kopia.sbbh.cloud
   ```

2. **Navigate to Snapshots**
   - Click "Snapshots" in the sidebar
   - Find the source: `<app-name>@<namespace>:/data`
   - Browse available snapshots by date/time

3. **Restore Specific Files**
   - Select the snapshot to restore from
   - Browse the directory tree
   - Right-click files/folders to download or restore

### Scenario 3: Restore to Different Snapshot

By default, restore uses the latest snapshot. To restore from a specific point in time:

1. **List Available Snapshots**
   ```bash
   # Via Kopia CLI in the kopia pod
   kubectl exec -n volsync-system deployment/kopia -- \
     kopia snapshot list <app-name>@<namespace>:/data
   ```

2. **Modify ReplicationDestination**
   ```yaml
   spec:
     kopia:
       previous: 5  # Restore from 5th most recent snapshot
       # OR
       restoreTime: "2025-11-10T12:00:00Z"  # Restore from specific time
   ```

## Automatic Restore for New Deployments

The VolSync component template enables **automatic restore from backup** when deploying applications to a new cluster or namespace.

### How It Works

When you add the VolSync component to an application's `kustomization.yaml`, it creates:

1. **ReplicationDestination** - Configured with `trigger.manual: restore-once`
2. **PVC with dataSourceRef** - Points to the ReplicationDestination as its data source

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP}
spec:
  accessModes: ["${VOLSYNC_ACCESSMODES}"]
  storageClassName: ${VOLSYNC_STORAGECLASS}
  resources:
    requests:
      storage: ${VOLSYNC_CAPACITY}
  dataSourceRef:
    kind: ReplicationDestination
    apiGroup: volsync.backube
    name: ${APP}-dst
```

### Deployment Flow

#### Scenario A: New Deployment with Existing Backups

1. **Initial Deployment**
   - Flux applies the Kustomization
   - ReplicationDestination is created first
   - VolSync detects `trigger.manual: restore-once`
   - Restore job runs automatically (one-time only)

2. **PVC Creation**
   - After restore completes, PVC is created
   - `dataSourceRef` tells Kubernetes to use restored data
   - Volume is provisioned with data from backup

3. **Application Startup**
   - Pod starts and mounts the restored PVC
   - Application has access to all backed-up data

#### Scenario B: New Deployment WITHOUT Existing Backups

If no backup exists in the Kopia repository:

1. ReplicationDestination enters error state
2. PVC creation is blocked (cannot use dataSourceRef)
3. **Resolution:** Remove the VolSync component temporarily:
   ```yaml
   # In kustomization.yaml, comment out:
   # components:
   #   - ../../../../components/volsync
   ```
4. Create a standard PVC without dataSourceRef
5. Let application run and create initial data
6. Re-add VolSync component to start backups

### Configuration for Auto-Restore

In the application's Flux Kustomization (`ks.yaml`):

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  path: ./kubernetes/apps/default/myapp/app
  postBuild:
    substitute:
      APP: myapp
      VOLSYNC_CAPACITY: "10Gi"
      VOLSYNC_STORAGECLASS: "ceph-block"
      VOLSYNC_PUID: "1000"
      VOLSYNC_PGID: "1000"
```

### Testing Auto-Restore

To test the auto-restore functionality:

```bash
# 1. Delete the application and its PVC
kubectl delete -n <namespace> deployment/<app-name>
kubectl delete -n <namespace> pvc/<app-name>

# 2. Delete the ReplicationDestination to reset restore trigger
kubectl delete -n <namespace> replicationdestination/<app-name>-dst

# 3. Let Flux recreate everything
flux reconcile kustomization <app-name> --with-source

# 4. Watch the restore process
kubectl get replicationdestination <app-name>-dst -n <namespace> -w

# 5. Verify PVC is created with restored data
kubectl get pvc <app-name> -n <namespace>
kubectl describe pvc <app-name> -n <namespace> | grep "Used By"
```

### Important Notes

- **One-Time Only:** The restore trigger `restore-once` ensures the restore only happens during initial deployment
- **Subsequent Updates:** After initial restore, only scheduled backups run (no more restores)
- **Manual Re-trigger:** To restore again, change the trigger value:
  ```bash
  kubectl patch replicationdestination <app>-dst -n <namespace> \
    --type merge -p '{"spec":{"trigger":{"manual":"restore-'$(date +%s)'"}}}'
  ```
- **Backup Source:** The component automatically sets the Kopia snapshot path to `<app-name>@<namespace>:/data`

## Configuration Variables

Applications using the VolSync component can customize behavior via these variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `APP` | (required) | Application name, used for resource naming |
| `VOLSYNC_CAPACITY` | `5Gi` | Size of PVC for restore |
| `VOLSYNC_ACCESSMODES` | `ReadWriteOnce` | Access mode for the restored PVC |
| `VOLSYNC_STORAGECLASS` | `ceph-block` | StorageClass for the restored PVC |
| `VOLSYNC_SNAPSHOTCLASS` | `csi-ceph-blockpool` | VolumeSnapshotClass for Ceph snapshots |
| `VOLSYNC_CACHE_ACCESSMODES` | `ReadWriteOnce` | Access mode for cache PVC |
| `VOLSYNC_CACHE_SNAPSHOTCLASS` | `openebs-hostpath` | StorageClass for cache |
| `VOLSYNC_PUID` | `1000` | User ID for mover pod |
| `VOLSYNC_PGID` | `1000` | Group ID for mover pod |

## Storage Architecture

### Ceph RBD (Primary Storage)
- **StorageClass:** `ceph-block`
- **Provisioner:** `rook-ceph.rbd.csi.ceph.com`
- **Features:**
  - Block storage for application PVCs
  - Snapshot support via CSI driver
  - High performance, low latency
  - Replicated across Ceph OSDs

### OpenEBS HostPath (Cache Storage)
- **StorageClass:** `openebs-hostpath`
- **Purpose:** Temporary cache for backup/restore operations
- **Lifecycle:** Created per backup/restore, deleted after completion
- **Size:** 5Gi (matches PVC size)

### NFS (Backup Repository)
- **Server:** `nas-k8s.int.sbbh.cloud`
- **Path:** `/data/nvme/k8s/volsync.kopia`
- **Purpose:** Long-term backup storage
- **Format:** Kopia repository (content-addressable, encrypted)

## Common Operations

### Add Backup to New Application

1. Add VolSync component to `kustomization.yaml`:
   ```yaml
   components:
     - ../../../../components/volsync
   ```

2. Configure variables in the app's Flux Kustomization:
   ```yaml
   postBuild:
     substitute:
       APP: myapp
       VOLSYNC_CAPACITY: "10Gi"
   ```

3. Commit and push changes. Flux will automatically:
   - Create ExternalSecret for Kopia credentials
   - Create ReplicationSource for backups
   - Start hourly backups

### Manually Trigger Backup

Backups run hourly, but you can trigger immediately:

```bash
# Option 1: Delete the VolumeSnapshot to force recreation
kubectl delete volumesnapshot volsync-<app-name>-src -n <namespace>

# Option 2: Update the ReplicationSource trigger
kubectl patch replicationsource <app-name> -n <namespace> \
  --type merge -p '{"spec":{"trigger":{"manual":"backup-now"}}}'
```

### Check Backup Repository Size

```bash
# Via Kopia pod
kubectl exec -n volsync-system deployment/kopia -- \
  kopia repository status

# Via NFS mount (from a node)
ssh <node> "du -sh /path/to/nfs/mount/volsync.kopia"
```

### Prune Old Snapshots

Kopia automatically prunes based on retention policy, but you can manually trigger:

```bash
kubectl exec -n volsync-system deployment/kopia -- \
  kopia maintenance run --full
```

### List All Backed Up Applications

```bash
kubectl exec -n volsync-system deployment/kopia -- \
  kopia snapshot list --all
```

## Troubleshooting

### Issue: Snapshots Stuck in Deletion

**Symptoms:**
- VolumeSnapshots exist with deletionTimestamp set
- VolumeSnapshotContent objects stuck with deletionTimestamp
- Backups fail with "data PVC not available"
- Alert: `VolSyncVolumeOutOfSync`
- Events show: `Failed to delete snapshot`

**Cause:** Ceph CSI driver failed to delete snapshot, leaving finalizers

**Resolution Steps:**

1. **Identify stuck snapshots:**
   ```bash
   # Check VolumeSnapshots
   kubectl get volumesnapshot -A -o json | \
     jq -r '.items[] | select(.metadata.deletionTimestamp) | "\(.metadata.namespace)/\(.metadata.name)"'

   # Check VolumeSnapshotContent (cluster-scoped)
   kubectl get volumesnapshotcontent -o custom-columns=NAME:.metadata.name,DELETION_TIME:.metadata.deletionTimestamp | \
     grep -v "<none>"
   ```

2. **Remove finalizers from stuck resources:**
   ```bash
   # For VolumeSnapshots
   kubectl patch volumesnapshot <snapshot-name> -n <namespace> \
     --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'

   # For VolumeSnapshotContent (more common)
   kubectl patch volumesnapshotcontent <snapcontent-name> \
     --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
   ```

3. **Batch removal for multiple stuck snapshots:**
   ```bash
   # Save list of stuck VolumeSnapshotContent objects
   kubectl get volumesnapshotcontent -o json | \
     jq -r '.items[] | select(.metadata.deletionTimestamp) | .metadata.name' > /tmp/stuck-snapshots.txt

   # Remove finalizers from all
   cat /tmp/stuck-snapshots.txt | xargs -I {} \
     kubectl patch volumesnapshotcontent {} \
     --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
   ```

4. **Verify cleanup:**
   ```bash
   # Should return 0 if all cleared
   kubectl get volumesnapshotcontent -o json | \
     jq '.items | map(select(.metadata.deletionTimestamp)) | length'
   ```

**Important Notes:**
- Delete events may persist in the event log for ~1 hour even after successful deletion
- These are transient warnings and can be ignored if the snapshots no longer exist
- New backups should proceed normally after cleanup

### Issue: CSI Driver Operation Conflicts

**Symptoms:**
- CSI logs show: `an operation with the given Volume ID ... already exists`
- Multiple VolumeSnapshotContent objects stuck in deletion
- Backups fail repeatedly with `SnapshotDeleteError`
- Errors persist even after removing finalizers manually

**Root Cause:**
The Ceph CSI driver maintains an in-memory operation tracker to prevent concurrent operations on the same volume. When finalizers are manually removed, the driver's memory gets out of sync with the actual state, causing it to reject all subsequent deletion attempts for those volume IDs.

**Resolution:**

1. **Verify no critical operations are running:**
   ```bash
   # Check for active VolSync mover pods
   kubectl get pods -A | grep "volsync.*mover"

   # Verify no active restore operations
   kubectl get replicationdestination -A -o json | \
     jq -r '.items[] | select(.status.lastSyncStartTime != null and .status.lastSyncTime == null)'

   # Ensure all PVCs are in Bound state
   kubectl get pvc -A | grep -v Bound
   ```

2. **Restart CSI RBD controller pods:**
   ```bash
   # Find the CSI RBD controller pods
   kubectl get pods -n rook-ceph | grep rbd.csi.ceph.com-ctrlplugin

   # Delete both pods (they will be recreated by the deployment)
   kubectl delete pods -n rook-ceph -l app=csi-rbdplugin-provisioner

   # Wait for new pods to be ready
   kubectl wait --for=condition=ready pod -n rook-ceph -l app=csi-rbdplugin-provisioner --timeout=120s
   ```

3. **Force leader re-election (if needed):**
   ```bash
   # Delete the stale leader lease
   kubectl delete lease -n rook-ceph external-snapshotter-leader-rook-ceph-rbd-csi-ceph-com

   # Wait a few seconds for new leader election
   sleep 10

   # Verify new leader
   kubectl get lease -n rook-ceph external-snapshotter-leader-rook-ceph-rbd-csi-ceph-com \
     -o jsonpath='{.spec.holderIdentity}'
   ```

4. **Remove finalizers from any remaining stuck snapshots:**
   ```bash
   # This should now succeed with the refreshed CSI driver
   kubectl get volumesnapshotcontent -o json | \
     jq -r '.items[] | select(.metadata.deletionTimestamp) | .metadata.name' | \
     xargs -I {} kubectl patch volumesnapshotcontent {} \
     --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
   ```

5. **Verify system health:**
   ```bash
   # Check CSI driver logs for errors
   kubectl logs -n rook-ceph -l app=csi-rbdplugin-provisioner -c csi-snapshotter --tail=50

   # Confirm no stuck snapshots remain
   kubectl get volumesnapshotcontent -o custom-columns=NAME:.metadata.name,DELETION_TIME:.metadata.deletionTimestamp | \
     grep -v "<none>" | wc -l

   # Verify VolSync can create new backups
   kubectl get replicationsource -A -o wide
   ```

**Prevention:**
- This issue typically occurs after manual finalizer removal
- CSI driver restart clears the in-memory operation tracker
- Future finalizer removals may require the same CSI restart procedure
- Consider investigating underlying Ceph issues if this becomes frequent

### Issue: Backup Fails with "Repository Not Found"

**Symptoms:**
- Mover pod logs show: `repository not initialized`
- No Kopia repository in NFS path

**Resolution:**
```bash
# Initialize repository via Kopia pod
kubectl exec -n volsync-system deployment/kopia -- \
  kopia repository create filesystem --path=/repository
```

### Issue: Restore Hangs or Never Completes

**Symptoms:**
- ReplicationDestination stays in "Synchronizing" state
- No mover pod created

**Resolution:**
```bash
# Check ReplicationDestination events
kubectl describe replicationdestination <app-name>-dst -n <namespace>

# Common issues:
# 1. Snapshot doesn't exist in repository
# 2. Kopia credentials incorrect
# 3. NFS mount issues

# Verify snapshot exists
kubectl exec -n volsync-system deployment/kopia -- \
  kopia snapshot list <app-name>@<namespace>:/data

# Test NFS connectivity
kubectl run -it --rm nfs-test --image=busybox --restart=Never -- \
  mount -t nfs nas-k8s.int.sbbh.cloud:/data/nvme/k8s/volsync.kopia /mnt
```

### Issue: Backup Takes Too Long

**Symptoms:**
- `lastSyncDuration` is hours instead of minutes
- Timeouts during backup

**Causes and Solutions:**

1. **Large dataset:**
   - First backup is always slow (full copy)
   - Subsequent backups are incremental and faster

2. **Network issues:**
   ```bash
   # Test NFS performance
   kubectl exec -n volsync-system deployment/kopia -- \
     dd if=/dev/zero of=/repository/test bs=1M count=1000
   ```

3. **Increase parallelism:**
   ```yaml
   spec:
     kopia:
       parallelism: 4  # Default is 2
   ```

### Issue: Out of Sync Alerts

**Symptoms:**
- Alert: `VolSyncVolumeOutOfSync` firing
- Metric: `volsync_volume_out_of_sync == 1`

**Expected Behavior:**
- Metric is `1` between scheduled backup times
- Metric is `0` only during and immediately after backup

**Actual Issue if Persistent:**
- Check `lastSyncTime` is recent (within last hour)
- Check for errors in ReplicationSource status
- Review troubleshooting steps above

### Issue: Kopia Web UI Shows "Repository Locked"

**Cause:** Another process (backup/restore) is using the repository

**Resolution:**
```bash
# Wait for backup/restore to complete, or force unlock (dangerous!)
kubectl exec -n volsync-system deployment/kopia -- \
  kopia repository unlock
```

## Monitoring & Alerts

### Prometheus Metrics

VolSync exports metrics at: `http://volsync-system.svc.cluster.local:8080/metrics`

Key metrics:
- `volsync_volume_out_of_sync{obj_namespace, obj_name}` - 1 if backup needed
- `volsync_missed_interval_count_total` - Count of missed backups

### Configured Alerts

**VolSyncVolumeOutOfSync** (Critical)
- Fires when: Volume hasn't synced in >5 minutes after scheduled time
- Location: `kubernetes/apps/volsync-system/kustomization.yaml` (alerts component)
- Check: `kubectl get prometheusrule -A | grep volsync`

## Security Considerations

### Encryption
- **At Rest:** All backups encrypted with AES-256 by Kopia
- **Password:** Stored in Vault at `ops/infra/kopia`
- **Transport:** Data travels over NFS (consider encryption if untrusted network)

### Access Control
- Kopia UI requires authentication
- Repository password required for all operations
- Mover pods run as non-root (UID/GID 1000)
- Read-only root filesystem in mover pods

### Backup Integrity
- Kopia uses content-addressable storage (CAS)
- Each block has SHA256 hash verification
- Corruption detected automatically on restore

## References

- [VolSync Documentation](https://volsync.readthedocs.io/)
- [Kopia Documentation](https://kopia.io/docs/)
- [Ceph RBD CSI](https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/)
- [VolumeSnapshot API](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)

## Support

For issues specific to this setup:
1. Check pod logs: `kubectl logs -n volsync-system <pod>`
2. Review Flux reconciliation: `flux get kustomizations -n flux-system`
3. Check Kopia repository status via web UI: https://kopia.sbbh.cloud
