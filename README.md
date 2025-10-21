# Skill Certificate Smart Contract

This repository contains a Clarity smart contract for issuing, verifying, and revoking skill certificates on the Stacks blockchain.

## Features

- **Admin Management:** Assign and change contract admin.
- **Issuer Management:** Add or remove authorized certificate issuers.
- **Certificate Issuance:** Issue certificates with metadata, course info, and validity period.
- **Certificate Revocation:** Revoke certificates by admin or issuer.
- **Verification:** Check certificate validity and details on-chain.

## Contract Overview

- **Admin:** The contract deployer is the initial admin and can transfer admin rights.
- **Issuers:** Only admin can add or remove issuers. Issuers can issue certificates.
- **Certificates:** Each certificate includes recipient, issuer, course, metadata, issue block, expiry block, and revocation status.

## Functions

| Function                       | Type         | Description                                      |
|--------------------------------|--------------|--------------------------------------------------|
| `set-admin`                    | Public       | Change the contract admin                        |
| `add-issuer`                   | Public       | Add a new certificate issuer                     |
| `remove-issuer`                | Public       | Remove an issuer                                 |
| `issue-certificate`            | Public       | Issue a new certificate                          |
| `revoke-certificate`           | Public       | Revoke an existing certificate                   |
| `is-admin`                     | Read-only    | Check if an address is admin                     |
| `is-active-issuer`             | Read-only    | Check if an address is an active issuer          |
| `get-certificate`              | Read-only    | Get certificate details by ID                    |
| `is-certificate-valid`         | Read-only    | Check if a certificate is valid                  |
| `get-certificate-count`        | Read-only    | Get the total number of certificates issued      |
| `get-issuer`                   | Read-only    | Get issuer details by address                    |

## Usage

1. **Deploy the contract** to the Stacks blockchain.
2. **Admin** adds issuers using `add-issuer`.
3. **Issuers** issue certificates to recipients using `issue-certificate`.
4. **Certificates** can be revoked by the issuer or admin using `revoke-certificate`.
5. **Anyone** can verify certificates using `get-certificate` and `is-certificate-valid`.

## Development

- Written in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-lang).
- Compatible with [Clarinet](https://docs.hiro.so/clarinet/get-started) for local development and testing.
