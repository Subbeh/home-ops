# Installation

## Prerequisites

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

3. Bootstrap the cluster

    ```sh
    task k8s:talos:init:bootstrap
    ```

4. Get the kubeconfig file

    ```sh
    task k8s:talos:init:kubeconfig
    ```
