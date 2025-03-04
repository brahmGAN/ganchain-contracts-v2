## Overview

The Subnet System allows "Kings" (network administrators) to create their own subnets and register providers who contribute resources to these networks. Each subnet defines specific resource requirements that providers must meet to join.

## Architecture

The system consists of two primary contracts:

1. **SubnetFactory**: A factory contract that allows Kings to create their own subnets
2. **Subnet**: Individual subnet instances that manage provider registration and verification

## SubnetFactory Contract

The SubnetFactory contract is the entry point for creating new subnets:

- It allows any user with enough stake to create their own subnet
- It maintains registries of all subnets and which King created which subnets
- It provides lookup functions to find subnet addresses

### Key Functions

- `createSubnet()`: Creates a new subnet with the caller as the King
- `getKingSubnets()`: Returns all subnets created by a specific King
- `getAllSubnets()`: Returns all subnets created through the factory

## Subnet Contract

Each Subnet contract is an individual network managed by a King:

- Kings can register and verify providers who meet resource requirements
- Each subnet maintains a list of active providers
- Operations require the King to maintain minimum stake levels

### Key Functions

- `registerAndVerifyProvider()`: Registers and verifies a provider in one step
- `removeProvider()`: Removes a provider from the subnet
- `getAllProviders()`: Returns all active providers in the subnet
- `getProviderCount()`: Returns the number of active providers

