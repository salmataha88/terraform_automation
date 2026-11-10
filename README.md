# GCE VM Terraform

A reusable Terraform module for a Compute Engine VM with persistent disks and an optional reserved public IP. Each root under `machines/` uses its own GCS state prefix.

## Configure a machine

Use the version-controlled files under `machines/example-vm` as the template for a new machine root. In the machine's folder, copy the example files to their local names. For a checkout with existing local settings, keep those files.

```powershell
Set-Location machines/example-vm
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.tfbackend.example backend.tfbackend
```

- In `terraform.tfvars`, fill in the project, VM and disk settings, and runtime service account. For a static IP, supply its reserved address and resource name.
- In `backend.tfbackend`, set an existing GCS bucket and a prefix unique to this machine. Use the same bucket and prefix when continuing to manage a machine already in Terraform state.
- Use Google Application Default Credentials for authentication. For interactive local use, run `gcloud auth application-default login` with an account that can access the project and state bucket.

```powershell
terraform init -backend-config=backend.tfbackend
terraform plan
```

## Adopt existing resources

Copy `imports.tf.example` to `imports.local.tf`, fill in the resource IDs, and include only blocks for resources managed by this root. Match the values in `terraform.tfvars` to the live configuration. For adoption without infrastructure changes, check that the plan shows only imports and no adds, changes, or destroys before applying it. Remove `imports.local.tf` after successful import.

## Move to a different zone

Take a snapshot of the boot disk and each data disk. Apply `deletion_protection = false` to the existing VM first. Then update `zone` and each disk's `snapshot` in `terraform.tfvars` and review the replacement plan. The regional static address can be reused within the same region. Re-enable deletion protection after the move. Reattach any externally managed schedule to the replacement VM.

## What belongs in Git

Commit the reusable code, the example files with fictional values, and `.terraform.lock.hcl`. The real `terraform.tfvars`, `backend.tfbackend`, and `imports.local.tf` are ignored, as are local Terraform state and saved plans. Treat the remote state and saved plans as private because they can include infrastructure details and input values. Keep credentials in ADC or the CI secret store.
