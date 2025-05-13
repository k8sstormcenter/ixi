---
kind: unit

title: Signing the artefact

name: oci-sign
---

## Authentication

Bob Artifacts works with Docker Hub, GitHub and GitLab Container Registry,
ACR, ECR, GAR, Harbor, self-hosted Docker Registry and
any other registry which supports custom OCI media types.

For authentication purposes, the `bobctl <verb> artifact` commands are using the `~/.docker/config.json`
config file and the Docker credential helpers.

__NOTE__: Login to GitHub Container Registry example:

```shell
echo ${GITHUB_PAT} | docker login ghcr.io -u ${GITHUB_USER} --password-stdin
```

__Note__: We use local lab registry `registry.iximiuz.com`!

To pull artifacts in Kubernetes clusters, BoB Operator can authenticate to container registries
using image pull secrets or IAM role bindings to the `bob-controller` service account.

Generate an image pull secret for GitHub Container Registry example:

```shell
bobctl create secret oci ghcr-auth \
  --url=ghcr.io \
  --username=bob \
  --password=${GITHUB_PAT}
```

Then reference the secret in the `OCIRepository` with:

```yaml
apiVersion: source.k8sstormcenter.io/v1alpha1
kind: OCIRepository
metadata:
  name: k8sstormcenter-honey
  namespace: default
spec:
  interval: 5m
  url: oci://registry.iximiuz.com/k8sstormcenter/manifests/honey
  provider: generic
  secretRef:
    name: ghcr-auth
```

### Contextual Authorization

When running BoB on managed Kubernetes clusters like EKS, AKS or GKE, you
can set the `provider` field to `azure`, `aws` or `gcp` and BoB will use
the Kubernetes node credentials or an IAM Role binding to pull artifacts
without needing an image pull secret.

For more details on how to setup contextual authorization for Azure, AWS and Google Cloud please see:

- [OCIRepository documentation](/bob/components/source/ocirepositories/#provider)

## Signing and verification

BoB comes with support for verifying OCI artifacts signed with [Sigstore Cosign](https://github.com/sigstore/cosign)
or [Notaryproject notation](https://github.com/notaryproject/notation).

To secure your delivery pipeline, you can sign the artifacts and configure Flux
to verify the artifacts' signatures before they are downloaded and reconciled in production.

### Cosign Workflow example

```shell
COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep tag_name | cut -d '"' -f4)
curl -sLo cosign "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
chmod +x cosign
sudo mv cosign /usr/local/bin/
```

Generate a Cosign key-pair and create a Kubernetes secret with the public key:

```shell
cosign version
cosign generate-key-pair

kubectl -n default create secret generic cosign-pub \
  --from-file=cosign.pub=cosign.pub
```

Push and sign the artifact using the Cosign private key:

```shell
bobctl push artifact oci://registry.iximiuz.com/k8sstormcenter/manifests/honey:$(git tag --points-at HEAD) \
	--path="./kustomize" \
	--source="$(git config --get remote.origin.url)" \
	--revision="$(git tag --points-at HEAD)@sha1:$(git rev-parse HEAD)"

cosign sign --key=cosign.key registry.iximiuz.com//k8sstormcenter/manifests/honey:$(git tag --points-at HEAD)
```

Configure k8sstormcenter to verify the artifacts using the Cosign public key from the Kubernetes secret:

```yaml
apiVersion: source.k8sstormcenter.io/v1alpha1
kind: OCIRepository
metadata:
  name: k8sstormcenter-honey
  namespace: default
spec:
  interval: 5m
  url: oci://registry.iximiuz.com/k8sstormcenter/manifests/honey
  ref:
    semver: "*"
  verify:
    provider: cosign
    secretRef:
      name: cosign-pub
```

{{% alert color="info" title="Cosign Keyless" %}}
For publicly available OCI artifacts, which are signed using
the [Cosign Keyless](https://docs.sigstore.dev/cosign/keyless/)
method, you can enable the verification by omitting the `.verify.secretRef` field.

Note that keyless verification is an **experimental feature**, using
custom root CAs or self-hosted Rekor instances are not currently supported.
{{% /alert %}}

### Notary Workflow example

Generate a local signing key pair:

```shell
openssl req -x509 -sha256 -nodes -newkey rsa:2048 \
-keyout <name>.key \
-out <name>.crt \
-days 365 \
-subj "/C=DE/ST=NRW/L=Bochum/O=Notary/CN=<name>" \
-addext "basicConstraints=CA:false" \
-addext "keyUsage=critical,digitalSignature" \
-addext "extendedKeyUsage=codeSigning"
```

Configure notation to use the local key:

```shell
cat <<EOF > ~/.config/notation/signingkeys.json
{
    "default": "<key-name>"
    "keys": [
        {
            "name": "<key-name>",
            "keyPath": "<path-to-key>.key",
            "certPath": "<path-to-cert>.crt"
        }
    ]
}
```

You should now be able to list the keys:

```shell
notation key ls
```

It is also possible to generate a test certificate:

```shell
# Generate a certificate and RSA key pair
notation cert generate-test valid-example
```

{{% alert color="warning" title="Disclaimer" %}}
The test certificate is not suitable for production use. Please 
visit the [notation documentation](https://notaryproject.dev/docs/user-guides/how-to/plugin-management/)
for more information on how to use the notation plugin for production.
{{% /alert %}}

Push and sign the artifact using the certificate's private key:

```shell
bobctl push artifact oci://registry.iximiuz.com/k8sstormcenter/manifests/honey:$(git tag --points-at HEAD) \
	--path="./kustomize" \
	--source="$(git config --get remote.origin.url)" \
	--revision="$(git tag --points-at HEAD)@sha1:$(git rev-parse HEAD)"

notation sign registry.iximiuz.com/k8sstormcenter/manifests/honey:$(git tag --points-at HEAD) -k <key-name>
```

Create a `trustpolicy.json` file:

```json
{
    "version": "1.0",
    "trustPolicies": [
        {
            "name": "<policy-name>",
            "registryScopes": [ 
                "registry.iximiuz.com/k8sstormcenter/manifests/honey"
             ],
            "signatureVerification": {
                "level" : "strict" 
            },
            "trustStores": [ "ca:<store-name>" ],
            "trustedIdentities": [
                "x509.subject: C=DE, ST=NRW, L=Bochum, O=Notary, CN=<name>"
            ]
        }
    ]
}
```

{{% alert color="info" title="Notation trust policy" %}}
For more details see [trust policy spec](https://github.com/notaryproject/specifications/blob/main/specs/trust-store-trust-policy.md#trust-policy)
{{% /alert %}}

Generate a kubernetes secret with the certificate and trust policy:

```shell
bobctl create secret notation notation-cfg \
    --namespace=<namespace> \
    --trust-policy-file=<trust-policy-file-path> \
    --ca-cert-file=<ca-cert-file-path>
```

Configure Bob to verify the artifacts using the Notary trust policy and certificate:

```yaml
apiVersion: source.k8sstormcenter.io/v1alpha1
kind: OCIRepository
metadata:
  name: k8sstormcenter-honey
  namespace: default
spec:
  interval: 5m
  url: oci://registry.iximiuz.com/k8sstormcenter/manifests/honey
  ref:
    semver: "*"
  verify:
    provider: notation
    secretRef:
      name: notation-cfg
```

### Verification status

If the verification succeeds, BoB adds a condition with the
following attributes to the OCIRepository's `.status.conditions`:

- `type: SourceVerified`
- `status: "True"`
- `reason: Succeeded`

If the verification fails, BoB will set the `SourceVerified` status to `False`
and will not fetch the artifact contents from the registry. The verification
failure will report this to the OCIRepository ready status message.

```console
$ kubectl -n default describe ocirepository.source.k8sstormcenter.io k8sstormcenter-honey

Status:                        
  Conditions:
    Last Transition Time:     2025-04-18T00:42:21Z
    Message:                  failed to verify the signature using provider 'cosign': no matching signatures were found
    Observed Generation:      1
    Reason:                   VerificationError
    Status:                   False
    Type:                     Ready
```

Verification failures are also visible when running `bobctl get sources oci` and in Kubernetes events.

## Git commit status updates

Another important reason to specify the Git revision when publishing
artifacts with `bobctl push` is for benefiting from BoB's integration
with Git notification providers that support commit status updates:

```shell
bobctl push artifact oci://<repo url> --path=<manifests dir> \
	--source="$(git config --get remote.origin.url)" \
	--revision="$(git branch --show-current)@sha1:$(git rev-parse HEAD)"
```

When `bob-controller` finds OCI artifacts containing a revision
specified like in the example above, this *origin revision* is added
on events.


