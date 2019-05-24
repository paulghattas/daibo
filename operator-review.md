# Testing your Operator with Operator Framework

These instructions walk you through how to test if your Operator deploys correctly with Operator Framework.

The process below assume that you have an Kubernetes Operator in the Operator Framework *bundle* format, for example:

```bash
$ ls my-operator/
my-operator.v1.0.0.clusterserviceversion.yaml
my-operator-crd1.crd.yaml
my-operator-crd2.crd.yaml
my-operator.package.yaml
```

where *my-operator* is the name of your Operatpr. If you don't have this format yet, refer to our [README](https://github.com/operator-framework/community-operators/blob/master/README.md). We will refer to this example of `my-operator` in the following instructions.

## Pre-Requisites

### Kubernetes cluster

For "upstream-community" operators targeting Kubernetes and [OperatorHub.io](https://operatorhub.io):
* A running Kubernetes cluster; [minikube](https://kubernetes.io/docs/setup/minikube/) is the simplest approach

For "community" operators targeting OCP/OKD and OperatorHub on OpenShift:
* either a running Kubernetes cluster; [minikube](https://kubernetes.io/docs/setup/minikube/) is the simplest approach
* or access to a running OpenShift 4 cluster, use [try.openshift.com](https://try.openshift.com/) to get a cluster on an AWS environment within ~30 mins

### Repositories

The following repositories are used throughout the process and should be cloned locally:

* [community-operators](https://github.com/operator-framework/community-operators)
* [operator-marketplace](https://github.com/operator-framework/operator-marketplace)
* [operator-courier](https://github.com/operator-framework/operator-courier)
* [operator-lifecycle-manager](https://github.com/operator-framework/operator-lifecycle-manager)

For simplicity, the following commands will clone all of the repositories above:

```
git clone https://github.com/operator-framework/operator-marketplace.git
git clone https://github.com/operator-framework/operator-courier.git
git clone https://github.com/operator-framework/operator-lifecycle-manager.git
```

Before you begin your current working dir should look like the following, with `my-operator` as an example for the name of your bundle:

```
my-operator
operator-marketplace
operator-courier
operator-lifecycle-manager
```

### Tools

#### operator-courier

`operator-courier` is used for metadata syntax checking and validation. This can be installed directly from `pip`:

```
pip3 install operator-courier
```

#### Quay Login

In order to test the Operator installation flow, store your Operator bundle on [quay.io](https://quay.io). You can easily create an account and use the free tier (public repositories only). To upload your Operator to quay.io a token is needed. This only needs to be done once and can be saved locally. The `operator-courier` repository has a script to retrieve the token:

```
./operator-courier/scripts/get-quay-token

Username: johndoe
Password: 
{"token": "basic abcdefghijkl=="}
```

A token takes the following form and should be saved in an environment variable:

```
export QUAY_TOKEN="basic abcdefghijkl=="
```
### Linting

`operator-courier` will verify the fields included in the Operator metadata (CSV). The fields can also be manually reviewed according to [the operator CSV documentation](https://github.com/operator-framework/community-operators/blob/master/docs/required-fields.md).

The following command will run `operator-courier` against the bundle directory `my-operator/` from the example above.

```
operator-courier verify --ui_validate_io my-operator/
```

If there is no output, the bundle passed `operator-courier` validation. If there are errors, your bundle will not work. If there are warning we still encourage you to fix them before proceeding to the next step.

### Push to quay.io

The Operator metadata in it's bundle format will be uploaded into your namespace in [quay.io](http://quay.io).

> The value for `PACKAGE_NAME` *must* be the same as in the operator's `*package.yaml` file and the operator bundle directory name. Assuming it is `my-operator`, this can be found by running `cat my-operator/*.package.yaml`.

> The `PACKAGE_VERSION` is entirely up for you to decide. Best practice is it coincides with your Operator version.

```
OPERATOR_DIR=my-operator/
QUAY_USERNAME=johndoe
PACKAGE_NAME=my-operator
PACKAGE_VERSION=1.0.0
TOKEN=$QUAY_TOKEN

operator-courier push $OPERATOR_DIR $QUAY_USERNAME $PACKAGE_NAME $PACKAGE_VERSION $TOKEN
```

Once that has completed, you should see it listed in your account's [Applications](https://quay.io/application/) tab.

> If the application has a lock icon, click through to the application and its Settings tab and select to make the application public.

Your Operator bundle is now ready for testing.

## Testing Operator Deployment on Kubernetes

Please ensure you have fulfilled the [pre-requisites](#pre-requisites) before continuing with the instructions below.

### 1. Get a Kubernetes cluster

Start a Kubernetes `minikube` cluster:

```
minikube start
```

### 2. Install OLM

Install OLM into the cluster in the `olm` namespace:

```
kubectl apply -f operator-lifecycle-manager/deploy/upstream/latest/
```

### 3. Install the Operator Marketplace

Install Operator Marketplace into the cluster in the `marketplace` namespace:

```
kubectl apply -f operator-marketplace/deploy/upstream/
```

### 4. Create the OperatorSource

An `OperatorSource` object is used to define the external datastore we are using to store operator bundles. More information including example can be found in the documentation included in the `operator-marketplace` [repository](https://github.com/operator-framework/operator-marketplace#operatorsource).

**Replace** `johndoe` in `metadata.name` and `spec.registryNamespace` with your quay.io username in the example below and save it to a file called `operator-source.yaml`.

```
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: johndoe-operators
  namespace: marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: johndoe
```

Now add the source to the cluster

```
kubectl apply -f operator-source.yaml
```

### 5. View Available Operators

Once the `OperatorSource` is deployed, the following command can be used to list the available operators (until an operator is pushed into quay, this list will be empty):

> The command below assumes `johndoe-operators` as the name of the `OperatorSource` object. Adjust accordingly.

```
kubectl get opsrc johndoe-operators -o=custom-columns=NAME:.metadata.name,PACKAGES:.status.packages -n marketplace
```

### 6. Create CatalogSourceConfig

Once the OperatorSource has been added, a `CatalogSourceConfig` needs to be created in the `marketplace` namespace to make those Operators available on cluster.

Create the following file as `catalog-source-config.yaml`:

```
apiVersion: operators.coreos.com/v1
kind: CatalogSourceConfig
metadata:
  name: johndoe-operators
  namespace: marketplace
spec:
  targetNamespace: operators
  packages: my-operator
```

In the above example:

* `operators` is a namespace that OLM is watching.
* `packages` is a comma-separated list of operators that have been pushed to quay.io and should be deployable by this source.

> The file above assumes `my-operators` as the name of the operator bundle. Adjust accordingly.

Deploy the `CatalogSourceConfig` resource:

```
kubectl apply -f catalog-source-config.yaml
```

When this file is deployed, a `CatalogSourceConfig` resource is created in the `marketplace` namespace.

```
kubectl get catalogsourceconfig -n marketplace
NAME                      STATUS      MESSAGE                                       AGE
johndoe-operators         Succeeded   The object has been successfully reconciled   93s
```

Additionally, a `CatalogSource` is created in the namespace indicated in `spec.targetNamespace` (in the above example, `operators`):

```
kubectl get catalogsource -n operators
NAME                           NAME                           TYPE   PUBLISHER   AGE
johndoe-operators                                             grpc               3m32s
```
### 7. Create an OperatorGroup

An `OperatorGroup` is used to denote which namespaces your Operator should be watching. It must in the namespace where your operator should be deployed, we'll use `default` in this example:

> If your Operator supports watching all namespaces (as indicated by `spec.installModes` in the CSV) you can omit the following step and place your `Subscription` in the `operators` namespace instead.


Create the following as the file `operator-group.yaml`

```
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: my-operatorgroup
  namespace: default
spec:
  targetNamespaces:
  - default
```

Deploy the `OperatorGroup` resource:

```
kubectl apply -f operator-group.yaml
```

### 8. Create a Subscription

The last piece ties together all of the previous steps. A `Subscription` is created to the operator.

```
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-operator-subsription
  namespace: default
spec:
  channel: <channel-name>
  name: my-operator
  source: johndoe-operators
  sourceNamespace: marketplace
```

### 9. Verify Operator health

Watch your Operator being deployed by OLM from the catalog source created by Operator Marketplace with the following command:

```
kubectl get clusterserviceversion -n default


```

> The above command assumes you have created the `Subscription` in the `default` namespace. Adjust accordingly if you have selected a different namespace.


If your Operator deployment (CSV) shows a `Succeeded` in the `InstallPhase` status, your Operator is deployed successfully.

Optional also check your Operator's deployment:

```
kubectl get deployment -n default
```

## Testing Operator Deployment on OpenShift

### 1. Create the OperatorSource

On OpenShift Container Platform and OKD 4.1 or newer `operator-marketplace` and `operator-lifeycle-manager` are already installed. You can start right away by creating an `OperatorSource` in the `openshift-marketplace` namespace as a user with the `cluster-admin` role:


### 2. Find your Operator in the OperatorHub UI

### 3. Install your Operator from OperatorHub

### 4. Verify Operator health

## Resources

* [Cluster Service Version Spec](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/design/building-your-csv.md)
* [Example Bundle](https://github.com/operator-framework/community-operators/tree/master/upstream-community-operators/etcd)
