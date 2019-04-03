# Prerequisites

## Cluster Access

For "upstream" operators:
* A running Kubernetes cluster; `minikube` is the simplest approach

For "community" operators:
* A running Kubernetes cluster; `minikube` is the simplest approach
* Access to a running OpenShift 4 cluster

## Repositories

The following repositories are used throughout the process and should be cloned locally:

* [Community Operators](https://github.com/operator-framework/community-operators)
* [Operator Marketplace](https://github.com/operator-framework/operator-marketplace)
* [Operator Courier](https://github.com/operator-framework/operator-courier)
* [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager)

For simplicity, the following commands will clone all of the repositories above:

```
git clone https://github.com/operator-framework/community-operators.git
git clone https://github.com/operator-framework/operator-marketplace.git
git clone https://github.com/operator-framework/operator-courier.git
git clone https://github.com/operator-framework/operator-lifecycle-manager.git
```

## Other

Operator Courier is used for metadata syntax checking and validation. This can be installed directly from `pip`:

```
pip3 install operator-courier
```

## Install and Configure Kubernetes

Optionally, delete the previous Kubernetes cluster:

```
minikube delete
```

Start the Kubernetes cluster:

```
minikube start
```

### Install OLM

Install OLM into the cluster and remove the default catalog source (a testing catalog source will be created later):

> Note: The first time the apply command is run, there may be errors. Simply run the command again to finish the OLM installation.

```
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.8.1/olm.yaml
kubectl delete catalogsource -n olm operatorhubio-catalog
```

### Install the Operator Marketplace

Install the Operator Marketplace. Unlike OLM, this is installed from a previously cloned repository. The second command here validates the installation by ensuring a `marketplace` namespace has been created.

```
kubectl apply -f operator-marketplace/deploy/upstream/ --validate=false
kubectl get ns | grep marketplace
```

At this point, the Kubernetes cluster is running and configured with the necessary pieces.
