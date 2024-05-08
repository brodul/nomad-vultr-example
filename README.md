# Nomad on Vultr

An example repo of running Hashicorp Nomad on Vultr with Traefik as a reverse proxy.

Slides can be found here:

https://2ly.link/1xvZY


## Create a Vultr account

Create a Vultr account and get a Vultr token.

## Terraform apply

First, ensure you have Terraform installed. Then, follow these steps:

1. Initialize Terraform:

    ```bash
    terraform init
    ```

2. Plan your infrastructure:

    ```bash
    terraform plan
    ```

3. Apply the changes:

    ```bash
    terraform apply
    ```

After applying, a `hostfile.txt` will be generated, which can be utilized for debugging and inspection using tools like `pssh`.

## Configuration

### Bootstrap ACL

Follow these steps to configure Bootstrap ACL:

1. Set the Nomad address:

    ```bash
    export NOMAD_ADDR="http://$(head -n 1 hosts.txt):4646"
    ```

2. Bootstrap Nomad:

    ```bash
    nomad acl bootstrap
    ```

If there is an error wait for a bit (5min), so that the cluster builds up.

3. Store the bootstrap token:

    ```bash
    echo "BOOTSTRAP_SECRET_ID" > bootstrap.token
    export NOMAD_TOKEN=$(cat bootstrap.token)
    ```

4. View Nomad server members:

    ```bash
    nomad server members
    ```

### Traefik Policy and Token

Apply policy for Traefik to access Nomad jobs:

```bash
nomad acl policy apply traefik traefik_acl_policy.nomad.hcl
```

Generate a token for Traefik:

```bash
nomad acl token create -name traefik_token -policy traefik
export TRAEFIK_TOKEN="TRAEFIK_SECRET_ID"
```

### Set Traefik Token and Deploy

Set the token and deploy Traefik:

```bash
nomad var put -namespace default nomad/jobs/traefik-system/traefik/server token=$TRAEFIK_TOKEN address=$NOMAD_ADDR
nomad job run traefik.nomad.hcl
```

### Deploy Whoami

Deploy Whoami service:

```bash
nomad job run whoami.nomad.hcl
```

## Warning

For production environments, consider implementing mTLS between clients and servers. Additionally, ensure better ACL configurations for sensitive variables like the Traefik token.
Traefik is listening to only one server.

## Contact
If you have any questions, suggestions, or feedback, feel free to reach out to me:

Email: andraz ․ brodnik AT brodul ․ org


## Contributing
We welcome contributions from the community to improve Nomad Balkan BBQ! If you'd like to contribute, please fork the repository, make your changes, and submit a pull request. We appreciate your help in making this project better for everyone.