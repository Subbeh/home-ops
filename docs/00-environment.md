# Environment Setup

1. Install `mise-en-place`

    ```sh
    # Arch Linux
    pacman -S mise

    # MacOS
    brew install mise
    ```

2. Clone repository

    ```sh
    git clone git@github.com:Subbeh/home-ops.git
    cd home-ops
    ```

3. Install dependencies

    ```sh
    mise trust
    mise install
    task init
    ```

# Environment variables

- Create secrets files

    ```sh
    task secrets:create:env-tf
    task secrets:create:env-cloudflare
    task secrets:create:env-hetzner
    ```

# Ansible

- Create ansible-vault key file

    ```sh
    task secrets:create:ansible-key
    ```
