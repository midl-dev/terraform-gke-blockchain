# Terraform-GKE-blockchain

A terraform module to deploy a GKE custer optimized for deploying blockchain nodes in the cloud.

Brought to you by [MIDL.dev](https://midl.dev), staking-as-a-service provider.

[Go to documentation](https://tezos-docs.midl.dev)

# Mode of operation

There are three ways of spinning up the infrastructure:

* from an user account and existing project
* from a terraform service account and no existing project (project gets created)
* from an existing project and existing kubernetes cluster

The way to select which of the ways to use is to pass different paramters.
