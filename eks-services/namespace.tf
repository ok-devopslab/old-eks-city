resource "kubernetes_storage_class_v1" "kubernetes_storage_class_v1" {
  storage_provisioner = "ebs.csi.aws.com"
  metadata {
    name = "gp3"
  }
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}
