# Identity Labs for Google Cloud

## Introduction

Identity is an important subject to study when when working in the cloud.
The labs in this repository were written to help you learn some of the concepts that come up in discussions
related to identity on Google Cloud.

## Repository layout

Each of the top-level folders in this repository represents a collection of labs based on a theme.
Each collection folder has another layer of folders representing indivitual labs.
Each lab has more detailed documentation with diagrams and instructions.

Here are the collections.

| Collection | Description |
| :--- | :--- |
| [oslogin](./oslogin/) | labs related to OS Login |
| [service-accounts](./service-accounts/) | labs related to service accounts |

The complete structure of the repository appears below.

<pre>
├── <a href="./oslogin" title="oslogin">oslogin</a>
│   │
│   └── <a href="./oslogin/oslogin-intro" title="oslogin-intro">oslogin-intro</a>
│
└── <a href="./service-accounts" title="service-accounts">service-accounts</a>
    │
    ├── <a href="./service-accounts/hub-spoke-projects" title="hub-spoke-projects">hub-spoke-projects</a>
    │
    └── <a href="./service-accounts/single-project" title="single-project">single-project</a>
</pre>

## Project requirements

Each lab will require one or more Google Cloud projects.
You should run these projects in locations that will not impact your production workloads.
You will likely need elevated privilges wthin your projects because these labs make project-level IAM changes and in 
some cases changes to organization policies.
You may wish to use a separate Google Cloud organization to keep things simple.

## Assumptions

1. You should be familiar with Google Cloud, the use of the console, and have a basic understanding of core services such as IAM, Organization Policy, Compute Engine, and Cloud Storage.

1. The lab instructions will be fairly comprehensive but not necessarily include every detail.

1. The labs may incude Terraform.
In such cases, you should be comfortable with common Terraform commands (e.g. init, plan, apply, destroy).
The instructions will tell you how to edit the configurations for your environment but if you know how to develop Terraform code you may gain additional insights into how the labs work.

1. The labs are meant for teaching concepts.
You should not use this code for production.

## Contributing

See the [CONTRIBUTING.md](./CONTRIBUTING.md) file for more information.
