# Installation

## Prerequisites

### Versions

1. Make sure the Kubernetes and Talos versions in the following files are synced:
    - `kubernetes/talos/machineconfig.yaml.j2`
    - `kubernetes/apps/system-upgrade/tuppr/upgrades/kubernetesupgrade.yaml`
    - `kubernetes/apps/system-upgrade/tuppr/upgrades/talosupgrade.yaml`

### GitHub

#### Flux Status Token

1. Create fine-grained access token in [GitHub](https://github.com/settings/personal-access-tokens)
    - Name: `flux-status-token`
    - Repository: `home-ops`
    - Repository Permissions:
        - Commit statuses (r/w)
        - Contents (r)
        - Metadata (r)
2. Save token in Bitwarden (NOTE: see [bitwarden config](https://github.com/Subbeh/dotfiles/tree/main/bitwarden))
    - Item: `github.com`
    - Field: `flux-status-token`

### Secrets

1. Run secrets task for all required secrets

    ```sh
    task secrets:create:[secret-name]
    ```

## Bootstrap Talos Cluster

1. Create `talsecret.yaml` file

    ```sh
    task k8s:talos:init:talsecret
    ```

2. Generate Talos config using

    ```sh
    task k8s:talos:init:genconfig
    ```

3. Apply the Talos configs

    ```sh
    task k8s:talos:init:apply:k8s-nuc
    task k8s:talos:init:apply:k8s-opti-01
    task k8s:talos:init:apply:k8s-opti-02
    ```

4. Bootstrap the cluster

    ```sh
    task k8s:talos:init:bootstrap
    ```

5. Get the kubeconfig file

    ```sh
    task k8s:talos:init:kubeconfig
    ```

## Bootstrap Kubernetes resources

1. Temporarily point api-server to one of the nodes in `.private/kubernetes/kubeconfig`:

    ```
    -      server: https://10.11.10.180:6443
    +      server: https://10.11.10.81:6443
    ```

2. Create namespaces

    ```sh
    task k8s:bootstrap:ns
    ```

3. Apply Helmfile CRDs

    ```sh
    task k8s:bootstrap:crds
    ```

4. Apply Helmfile apps

    ```sh
    task k8s:bootstrap:apps
    ```

5. Revert the api-server endpoint in `.private/talos/kubeconfig`:

    ```
    -      server: https://10.11.10.81:6443
    +      server: https://10.11.10.180:6443
    ```
