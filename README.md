# nomad-deploy-action

This repo will take a Nomad job, replace a string of "[[.version]]" with the input Docker tag, authorize itself with an AWS security group, and deploy the job file.

## Variables

| Variable              | Details                                                 | Example                                    |
|-----------------------|---------------------------------------------------------|--------------------------------------------|
| AWS_ACCESS_KEY_ID     | AWS Access Key for security group authorization.        | `AKIAIOSFODNN7EXAMPLE`                     |
| AWS_SECRET_ACCESS_KEY | AWS Secret Access Key for security group authorization. | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| AWS_SECURITY_GROUP    | AWS Security Group to allow deployment through.         | `sg-087a364e3473445852`                    |
| NOMAD_JOB             | The Nomad job file path.                                | `nomad-jobs/dev/app.nomad`                 |
| DOCKER_TAG            | The Docker tag to replace before deploying.             | `latest`                                   |
