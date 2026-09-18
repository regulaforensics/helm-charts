# Regula Kubernetes Helm Charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

### Classic Helm repository

Once Helm is set up properly, add the GitHub Pages repository as follows:

```
helm repo add regulaforensics https://regulaforensics.github.io/helm-charts
helm repo update
```

You can then run `helm search repo regulaforensics` to see the charts.

### OCI registry

The same public charts are also available as OCI artifacts from Amazon ECR Public. OCI support is enabled by default in Helm 3.8 and later. The repositories are public, so no registry login is required to pull a chart.

Unlike a classic Helm repository, an OCI registry has no `helm search repo` equivalent. Specify the chart and exact chart version when pulling or installing it:

```
helm pull oci://public.ecr.aws/e1s1a6l3/charts/docreader --version 2.16.0
helm pull oci://public.ecr.aws/e1s1a6l3/charts/faceapi --version 3.7.1
helm pull oci://public.ecr.aws/e1s1a6l3/charts/idv --version 1.15.0
```

For example, install or upgrade Docreader with:

```
helm upgrade --install docreader \
  oci://public.ecr.aws/e1s1a6l3/charts/docreader \
  --version 2.16.0
```

- [Docreader](https://github.com/regulaforensics/helm-charts/tree/main/charts/docreader)
- [FaceAPI](https://github.com/regulaforensics/helm-charts/tree/main/charts/faceapi)
- [IDV](https://github.com/regulaforensics/helm-charts/tree/main/charts/idv)

<!-- Keep full URL links to repo files because this README syncs from main to gh-pages.  -->
Chart documentation is available at [docs.regulaforensics.com](https://docs.regulaforensics.com).
