# Changelog

All notable changes to this repository will be documented in this file.

> The format is based on [Keep a Changelog](https://keepachangelog.com/en/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [⚒ Work in progress]

<!-- ### 🔨 Fixed

- ...

### 🚀 Added

- ...

### 🤖 Changed

- ...

### ❌ Deleted

- ... -->

## [0.1.0] - 2023-02-04

> Initialize this repository template to enable Power Platform developers start quickly with event driven architecture with Dataverse and Azure 😊

### 🚀 Added

- Core files of the repository: README.md, LICENSE, CONTRIBUTING.md and CODE_OF_CONDUCT.md
- Issue and pull request templates
- Azure Developer CLI template for the solution below - *Bicep infrastructure as code and Azure Functions app code*

![servicebus-csharp-function-dataverse](https://user-images.githubusercontent.com/23240245/194187578-dd13f3d7-22bb-486e-a54c-1a8242cc5e7a.jpg)

- `post-init-setup` PowerShell script to execute after the initialization of the repository to finalize the configuration of the prerequisites to be able to deploy the solution using the `azd up` command
- `provision-deploy` GitHub workflow to be able to provision the infrastructure in Azure and deploy the Azure Functions app code on push or pull request to `main` branch (*in specific folders*)

[⚒ Work in progress]: https://github.com/rpothin/servicebus-csharp-function-dataverse/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/rpothin/servicebus-csharp-function-dataverse/releases/tag/v0.1.0