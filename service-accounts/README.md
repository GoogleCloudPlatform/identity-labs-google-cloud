# Identity Labs for Google Cloud - Service Account Collection

## Introduction

This collection contains labs about Google Cloud [service accounts](https://cloud.google.com/iam/docs/service-account-overview).
Service accounts are non-user identities that provide credentials for attached services such as Compute Engine instances
Service accounts can be either principals or resources.
As a principal, a service account can have IAM roles and issue calls to Google Cloud APIs.
For example, if a service account has the Secret Admin role and is attached to a Compute Engine instance, a user could log into that instance and have the ability to manage secrets with the Secret Manager service.
As a resource, a service account is acted upon.
For example, a service account can have permissions that allow only certain principals to generate tokens from the service account.

## Repository layout

Here are the labs in this collection.

| Lab | Description |
| :--- | :--- |
| [single-project](./single-project) | using a single project to demonstrate an attached service account and service account impersonation |
| [hub-spoke-projects](./hub-spoke-projects) | sharing a service account in one project with a resource in another project |

Each lab has more detailed documentation with diagrams and instructions.
