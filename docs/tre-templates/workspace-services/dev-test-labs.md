# Azure DevTest Labs Service bundle

See: [https://azure.microsoft.com/services/devtest-lab/](https://azure.microsoft.com/services/devtest-lab/)

## Prerequisites

- [A base workspace bundle installed](../workspaces/base.md)

## Create and expose a VM via the Firewall

When this service used without a virtual desktop gateway it might be necessary to manually create and expose a VM via the TRE firewall. This method of exposing VMs is not recommended for large scale deployments given there will be multiple resources and rules to manually manage.

1. Create a DevTest Labs VM and open a port in the TRE firewall using the script provided.

    ```cmd
    Usage:
        ./create_and_expose_vm.sh [-l --lab-name]  [-t --tre_id] [-w --workspace_id] [-n --vm-name] [-i --image-name]

    Options:
        -l, --lab-name:            Name of the DevTest Lab
        -t, --tre_id               ID of the TRE
        -w, --workspace_id         ID of the workspace
        -n, --vm-name              Name of the VM
        -i, --image-name:          Name of the VM Image

    Example:

    ./templates/workspace_services/devtestlabs/create_and_expose_vm.sh --lab-name <lab_name> --tre-id <tre-id> --workspace-id <workspace-id> --vm-name <vmn-name> --image-name "Data Science Virtual Machine - Windows Server 2019"

    ```

2. Using the details provided by the script, and a remote desktop connection client connect to the VM.
