# Review Process

## Install and Configure Kubernetes

Optionally, delete the previous Kubernetes cluster:

```
minikube delete
```

Start the Kubernetes cluster:

```
minikube start
```

Install OLM into the cluster and remove the default catalog source (a testing catalog source will be created later):

> Note: The first time the apply command is run, there may be errors. Simply run the command again to finish the OLM installation.

```
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.8.1/olm.yaml
kubectl delete catalogsource -n olm operatorhubio-catalog
```

Install the Operator Marketplace. Unlike OLM, this is installed from a previously cloned repository. The second command here validates the installation by ensuring a `marketplace` namespace has been created.

```
kubectl apply -f operator-marketplace/deploy/upstream/ --validate=false
kubectl get ns | grep marketplace
```

At this point, the Kubernetes cluster is running and configured with the necessary pieces.