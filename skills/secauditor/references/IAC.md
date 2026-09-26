# IAC: Cloud, Container and Infrastructure-as-Code Security

Weight 2. Active when Dockerfiles, Kubernetes or Helm manifests, or IaC files (Terraform, CloudFormation, Bicep, Pulumi, CDK) exist. Re-normalization raises its effective weight when fewer dimensions are active.
Owns: container images and runtime settings, Kubernetes workload and RBAC settings, cloud resources declared in code (storage, network, IAM, encryption, metadata service), and the scanning and admission gates for them.
Not here: secrets in Dockerfiles and manifests (SECRET-R5 and SECRET-R1); CI token permissions (MISCFG-R6); Action and image pinning in CI (SUPPLY-R3).
Standards: CIS Docker, Kubernetes, and AWS benchmarks, NIST SP 800-190, Kubernetes Pod Security Standards.
Read first: every Dockerfile, the Kubernetes or Helm manifests, and the IaC modules that define storage, networking, IAM, and databases.

## Cards

### IAC-R1 Storage bucket or database reachable from the internet (quick)
- Leads: `scan.sh IAC-R1` lists `acl = "public-read"`, `Principal: "*"`, `0.0.0.0/0`, `publicly_accessible = true`, and public-access-block settings.
- Confirm: object storage is public (ACL, bucket policy with `Principal: "*"`, or no public-access block), a database is `publicly_accessible`, or a security group opens SSH, RDP, or database ports to `0.0.0.0/0`.
- Not a finding if: the bucket intentionally serves public static assets and holds nothing else (say so); access is limited to known CIDRs.
- Severity: Critical for buckets or databases holding non-public data; High for open admin ports.
- Fix: enable the public-access block, restrict policies to named principals, and limit ingress to known networks or a bastion.
- Verify the fix: the planned resource has no public ACL or `0.0.0.0/0` ingress on sensitive ports (for example in `terraform plan` output the acting agent reviews).
- Refs: CWE-284, CIS AWS 2.1

### IAC-R2 Wildcard or admin IAM granted to workloads (quick)
- Leads: `scan.sh IAC-R2` lists `Action: "*"`, `Resource: "*"`, `*FullAccess`, `AdministratorAccess`, `iam:PassRole`, and `cluster-admin` bindings.
- Confirm: a role, policy, or Kubernetes RBAC binding used by the application grants wildcard actions or resources, full-access managed policies, `iam:PassRole` on `*`, or cluster-admin.
- Not a finding if: the grant belongs to a break-glass or bootstrap role not used by workloads (cite it).
- Severity: Critical when a compromised workload gains account-wide or cluster-wide control; High otherwise.
- Fix: grant the specific actions on the specific resources the workload uses.
- Verify the fix: no workload policy contains `"*"` in Action or Resource.
- Refs: CWE-250, CWE-732, CIS AWS 1.16

### IAC-R3 Container runs privileged or as root (quick)
- Leads: `scan.sh IAC-R3` lists `USER`, `privileged: true`, `hostPath`, `hostNetwork`, `hostPID`, `runAsUser: 0`, and `allowPrivilegeEscalation`.
- Confirm: the image has no non-root `USER` after installs, or a pod runs `privileged`, with `hostPID`, `hostIPC`, or `hostNetwork`, mounts sensitive host paths (especially `/var/run/docker.sock`), or lacks `runAsNonRoot`, `allowPrivilegeEscalation: false`, and dropped capabilities.
- Not a finding if: a Pod Security Admission policy in `enforce` mode rejects these (cite the label).
- Severity: Critical for the docker socket or privileged mode; High for root with escalation; Medium otherwise.
- Fix: add a non-root `USER`, set `runAsNonRoot`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem`, and drop all capabilities; remove host mounts.
- Verify the fix: the manifest's securityContext has these settings and the Dockerfile ends with a non-root `USER`.
- Refs: CWE-250, NIST SP 800-190, Kubernetes Pod Security Standards (restricted)

### IAC-R4 Encryption, metadata protection, or audit logging off for cloud resources
- Leads: `scan.sh IAC-R4` lists `encrypted`, `kms_key_id`, `http_tokens`, CloudTrail, and flow-log settings.
- Confirm: databases, volumes, or buckets are created without encryption at rest, instances allow IMDSv1 (`http_tokens` not `required`), or audit logging (CloudTrail, flow logs) and key rotation are off.
- Not a finding if: account-level defaults enforce encryption and IMDSv2 (cite them in the IaC).
- Severity: High for unencrypted sensitive data or IMDSv1 on internet-facing hosts; Medium otherwise.
- Fix: enable encryption with KMS keys, require IMDSv2, and turn on audit logging and key rotation.
- Verify the fix: the resources set `encrypted = true` or a KMS key, and `http_tokens = "required"`.
- Refs: CWE-311, CIS AWS 2.2 and 5.6

### IAC-R5 Images unpinned, bloated, or unscanned
- Leads: `scan.sh IAC-R5` lists `FROM` lines, `ADD` of remote URLs, and image-scan steps.
- Confirm: base images use `:latest` or a floating tag with no digest, images carry build tools into production (no multi-stage build), `ADD` fetches remote URLs, there is no `HEALTHCHECK`, or no image or IaC scanner runs in CI (or it cannot fail the build).
- Not a finding if: images are digest-pinned and a blocking scanner runs.
- Severity: Medium.
- Fix: pin by digest, use a minimal multi-stage image, use `COPY`, and add a blocking scanner (Trivy, Checkov, or kube-linter).
- Verify the fix: every `FROM` has an `@sha256:` digest and the scanner step has no soft-fail flag.
- Refs: NIST SP 800-190, CWE-1357

## Also check
- Missing resource limits and a default-deny NetworkPolicy in Kubernetes.
- `automountServiceAccountToken` left on for pods that never call the API.
- Plaintext Kubernetes Secret manifests or `values.yaml` with real values (file under SECRET-R1).

## Paper controls (look protective, protect nothing)
- A Pod Security Admission label set to `warn` or `audit` only.
- A public-access-block resource that is not attached to the bucket.
- Pod-level `runAsNonRoot` overridden by a container `runAsUser: 0`.
- A restrictive IAM policy written but never attached while a `*FullAccess` policy grants the real access.
- A Checkov or Trivy step with `--soft-fail` or `|| true`.
- A non-root Dockerfile that re-escalates through `sudo` at runtime.
