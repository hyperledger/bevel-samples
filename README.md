[//]: # (##############################################################################################)
[//]: # (Copyright Accenture. All Rights Reserved.)
[//]: # (SPDX-License-Identifier: Apache-2.0)
[//]: # (##############################################################################################)

# Hyperledger Bevel Samples

You can use Bevel samples to set-up real world examples using Hyperledger Bevel, and learn how to build applications that can interact with blockchain networks using the different APIs offered by DLT networks. To learn more about Hyperledger Bevel, visit the [Bevel documentation](https://hyperledger-bevel.readthedocs.io/en/latest).

## Getting started with the Bevel samples

To use the Bevel samples, you need to first have a DLT network that you have deployed using Hyperledger Bevel. Ensure that you have installed all of the [Bevel prerequisites](https://hyperledger-bevel.readthedocs.io/en/latest/prerequisites.html). You can then follow the instructions to [install your choice of DLT network](https://hyperledger-bevel.readthedocs.io/en/latest/operationalguide.html).

Following three samples are provided with Hyperledger Bevel
- [Supplychain Application](#supplychain-application)
- [Distributed Identity Application](#distributed-identity-application)
- [DSCP Application](#dscp-application)

## Supplychain Application
The Supplychain reference application is an example of a common usecase for a blockchain: the supplychain. The application defines a consortium of multiple organizations. The application allows nodes to track products or goods along their chain of custody. It provides the members of the consortium all the relevant data to their product. 

The application has been implemented for Hyperledger Fabric, Quorum and R3 Corda, with full support for Hyperledger Besu coming soon. The platforms will slightly differ in behavior, but follow the same principles.

### Prerequisites

* The supplychain application requires that nodes have subject names that include a location field in the x.509 name formatted as such:
`L=<lat>/<long>/<city>`
* DLT network of 1 or more organizations; a complete supplychain network would have the following organizations
    - Supplychain (admin/orderer organization) 
    - Carrier
    - Store
    - Warehouse
    - Manufacturer

### Setup Guide

The setup process has been automated using Ansible scripts, GitOps, and Helm charts. 

The files have all been provided to use and require the user to populate the `network.yaml` file accordingly, following these steps:
1. Create a copy of the `network.yaml` you have used to set up your network and add the application specific key-values to it. Check samples in `examples/supplychain-app/configuration/samples`.

1. Update the following for each organization in the `gitops` section.
    - `git_url` and `git-repo` to your bevel-samples repo
    - `chart_source` to `examples/supplychain-app/charts`
1. Make sure that you have deployed the smart contracts for the platform of choice; along with the correct `network.yaml` for the DLT.
    - For R3 Corda, run the `platforms/r3-corda/configuration/deploy-cordapps.yaml`
    - For Hyperledger Fabric, run the `platforms/hyperledger-fabric/configuration/chaincode-ops.yaml`
    - For Quorum, no smart contracts need to be deployed beforehand.

### Deploying the supplychain-app
When having completed the Prerequisites and setup guide, deploy the supplychain app by executing the following command:

`ansible-playbook examples/supplychain-app/configuration/deploy-supplychain-app.yaml -e "@/path/to/application/network.yaml"`

### Testing/validating the supplychain-app
For testing the application, there are API tests included. For instructions on how to set this up, follow the `README.md` [here](examples/supplychain-app/tests/README.md).

More details [here](examples/supplychain-app/README.md).

---
## Distributed Identity Application

The Distributed Identity app (Indy Ref App) allows nodes to implement the concept of digital identities using blockchain.
There are 3 components
- Alice: Alice is the end user and a student.
- Faber: Faber is the university.
- Indy Webserver

In this usecase, Alice obtains a Credential from Faber College regarding the transcript. A connection is build between Faber College and Alice (onboarding process).Faber College creates and sends a Credential Offer to Alice. Alice creates a Credential Request and sends it to Faber College.Faber College creates the Credential for Alice. 
Alice now receives the Credential and stores it in her wallet.


### Prerequisites
An Indy network deployed using Bevel with 2 organizations:
- Authority
    - 1 Trustee
- University
    - 4 Steward nodes
    - 1 Endorser
A Docker repository

### Setup Guide

The setup process has been automated using Ansible scripts, GitOps, and Helm charts. 

The files have all been provided to use and require the user to populate the `network.yaml` file accordingly, following these steps:
1. Create a copy of the `network.yaml` you have used to set up your network and add the application specific key-values to it.

1. Update the following for each organization in the `gitops` section.
    - `git_url` and `git-repo` to your bevel-samples repo
    - `chart_source` to `examples/identity-app/charts`

1. Make sure that the required docker images are built and stored on the repository.

### Deploying the identity-app
When having completed the Prerequisites and setup guide, deploy the identity app by executing the following command:

`ansible-playbook examples/identity-app/configuration/deploy-identity-app.yaml -e "@/path/to/application/network.yaml"`

### Testing/validating the identity-app
For testing the application, there are API tests included. For instructions on how to set this up, follow the `README.md` [here](examples/identity-app/tests/README.md).

More details [here](examples/identity-app/README.md).

---
## DSCP Application

The DSCP (Digital Supply Chain Platform) application demonstrates benefits of distributed systems using a Substrate-based Blockchain network. There are three personas here: 
- OEM: Original Equipment manufacturer and the Buyer.
- TierOne: The main supplier.
- TierTwo: Third party supplier(s).

The main differentiator for this iuse case is its usage of Substrate-based Node: [dscp-node](https://github.com/inteli-poc/dscp-node). The usecase covers generic buyer-supplier transactions like order placement, acceptance, goods status update, transport and 3-way match. Additional feature is that this use cases uses IPFS to share files like test reports, lab conformity tests, and other documentation needed in an additive manufacturing industry.

### Prerequisites
A DSCP network deployed using Bevel with 3 organizations:
- OEM
- TierOne
- TierTwo

### Setup Guide

The setup process has been automated using Ansible scripts, GitOps, and Helm charts. 

The files have all been provided to use and require the user to populate the `network.yaml` file accordingly, following these steps:
1. Create a copy of the `network.yaml` you have used to set up your network and add the application specific key-values to it. Check samples in `examples/dscp-app/configuration/samples`.

1. Update the following for each organization in the `gitops` section.
    - `git_url` and `git-repo` to your bevel-samples repo
    - `chart_source` to `examples/dscp-app/charts`

1. Ensure that the required docker images are built and stored on the repository.

### Deploying the dscp-app
When having completed the Prerequisites and setup guide, deploy the DSCP app by executing the following command:

`ansible-playbook examples/dscp-app/configuration/deploy-dscp-app.yaml -e "@/path/to/application/network.yaml"`

### Testing/validating the dscp-app
For testing the application, there are API tests included. For instructions on how to set this up, follow the `README.md` [here](examples/dscp-app/tests/README.md).

More details [here](examples/dscp-app/README.md).

## License
Hyperledger Bevel source code files are made available under the Apache License, Version 2.0 (Apache-2.0), located in the LICENSE file. Hyperledger Bevel documentation files are made available under the Creative Commons Attribution 4.0 International License (CC-BY-4.0), available at http://creativecommons.org/licenses/by/4.0/.
