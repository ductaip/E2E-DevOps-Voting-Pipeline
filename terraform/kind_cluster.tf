resource "kind_cluster" "default" {
  name = "voting-app-cluster"
  node_image = "kindest/node:v1.27.3"
  wait_for_ready = true

  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    # 1 Web Server/App Node (Control Plane fits workloads in Kind)
    node {
      role = "control-plane"
      
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
    
    # Removed worker nodes to save RAM (12GB Host optimized)
  }
}
