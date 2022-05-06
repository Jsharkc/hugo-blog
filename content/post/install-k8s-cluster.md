---
title: kubeadm 安装 k8s
description: '安装 k8s，记录下来，备忘'
date: 2021-11-16T11:42:23+80:00
tags: ["k8s"]
---

### 1. 环境初始化

#### 1.1 安装并配置 Docker

##### 1.1.1 安装 Docker

安装 Docker 参考 [Docker安装](/post/centos7-install-docker/)

##### 1.1.2 配置 cgroup driver

编辑 /etc/docker/daemon.json 文件，没有则创建，添加如下内容：

```json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

##### 1.1.3 配置国内 registry

```json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors":["https://hub-mirror.c.163.com"]
}
```

##### 1.1.4 检查 cgroup driver

启动或重启 docker

启动 docker：

```shell
systemctl start docker
```

重启 docker：

```shell
systemctl restart docker
```

检查 cgroup driver 

```shell
docker info |grep Cgroup
```

输出：

> ​    Cgroup Driver: systemd



#### 1.2 初始化主机名和 hosts

3 台 CentOS 7 机器，如下

| ip            | Hostname  |
| ------------- | --------- |
| 192.168.10.16 | kubeadm1  |
| 192.168.10.17 | kubenode1 |
| 192.168.10.18 | kubenode2 |

##### 1.2.1 设置主机名

主节点设置主机名，父节点同理

```shell
hostnamectl set-hostname kubeadm1
```

##### 1.2.2 配置 hosts

编辑 /etc/hosts 文件，追加如下信息（3 台机器都要做）

```shell
192.168.10.16 kubeadm1
192.168.10.17 kubenode1
192.168.10.18 kubenode2
```

不配置 hosts 可能会报以下错误： 

```shell
[WARNING Hostname]: hostname "xxxx" could not be reached
[WARNING Hostname]: hostname "xxxx": lookup xxx on 114.114.114.114:53: no such host
```

#### 1.3 设置防火墙、关闭 SELINUX

##### 1.3.1 设置防火墙为 Iptables 并设置空规则

```sh
systemctl stop firewalld && systemctl disable firewalld
yum install -y iptables-services && systemctl start iptables && systemctl enable iptables && iptables -F && service iptables save
```

通过以下命令观察是否成功：

```sh
systemctl status firewalld
// Active: inactive (dead)
systemctl status iptables
// Active: active (exited)
iptables -L
// 规则全空
cat /etc/sysconfig/iptables
// 内容空
```

##### 1.3.2 关闭 swap、关闭 SeLinux

```sh
swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fatab
setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=disable/' /etc/selinux/config
```

通过以下命令观察是否成功：

```sh
free -m
// Swap: 行后面都是 0，则成功
cat /etc/selinux/config | grep '^SELINUX='
// SELINUX=disable 则成功
```

#### 1.4 调整内核参数，对于 K8S

```sh
cat > kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
cp kubernetes.conf /etc/sysctl.d/kubernetes.conf
sysctl -p /etc/sysctl.d/kubernetes.conf
```

#### 1.5 关闭不需要的服务

```sh
systemctl stop postfix && systemctl disable postfix
```

#### 1.6 kube-proxy 开启 ipvs 前置条件

```sh
modprobe br_netfilter

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```

### 2. 安装配置 master 节点

#### 2.1 安装 kubeadm

##### 2.1.1 配置 yum 源

在 /etc/yum.repos.d 目录下，创建 kubernetes.repo 文件，添加如下内容：

```shell
[kubernetes]
name=kubernetes
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-$basearch
enabled=1
gpgcheck=0
```

重建缓存：

```shell
yum clean all
yum makecache
```

##### 2.1.2 安装 kubeadm

```shell
yum -y install kubelet kebeadm kubectl
```

> 注：这里没有指定版本，安装后默认为最新版本。在配置 kubeadm config 的时候，我们会指定 kubernetesVersion 的版本。如果指定的版本和这里安装的版本不一致，会出现如下报错：

```shell
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR KubeletVersion]: the kubelet version is higher than the control plane version. This is not a supported version skew and may lead to a malfunctional cluster. Kubelet version: "1.21.0" Control plane version: "1.20.5"
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

> 所以，建议安装 kubelet、kubeadm 和 kubectl 的时候，可以通过如下方式指定版本：

```shell
yum -y install kubelet-1.20.5 kubeadm-1.20.5 kubectl-1.20.5
```

> k8s 版本要和 docker 版本匹配，具体匹配关系可以参考
>
> https://www.cnblogs.com/sylvia-liu/p/14884920.html
>
> https://blog.csdn.net/cd_yourheart/article/details/107559295
>
> 我用的 Docker 版本：19.03.9
>
> K8s 版本：1.20.5

安装完成以后，由于集群还没有建立，所以目前还无法启动 kubelet 服务。我们可以把 kubelet 服务暂时加入开机启动：

```shell
systemctl enable kubelet
```

#### 2.2 配置 kubeadm config

kubeadm config 有如下 2 种配置方式：

* 配置文件方式
* 命令行传参

##### 2.2.1 配置文件方式

可以通过如下方式，获取默认配置：

```shell
kubeadm config print init-defaults > init.yaml
```

会在当前目录下生成 init.yaml 文件，主要关注以下内容：

```shell
localAPIEndpoint:
  advertiseAddress: 1.2.3.4
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  imagePullPolicy: IfNotPresent
  name: node
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: k8s.gcr.io
kind: ClusterConfiguration
kubernetesVersion: v1.20.5
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
```

从默认配置中，我们可以看到

* advertiseAddress 改为 master ip 地址
* name 改为 master hostname
* imageRepository 使用的是 k8s.gcr.io，我们建议改成国内的镜像站
* kubernetesVersion 使用的是 v1.20.5，我们可以改成自己想要的版本
* networking 中只有 serviceSubnet，可能我们还关心 pod 的网络，pod 网络可以使用 podSubnet 指定

使用如下配置：

```shell
localAPIEndpoint:
  advertiseAddress: 192.168.10.16
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  imagePullPolicy: IfNotPresent
  name: kubeadm1
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.20.5
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
  podSubnet: 10.244.0.0/16
```

#### 2.2.2 命令参数方式

对应到 config 方式，有如下几个参数与之对应：

> --kubernetes-version：指定Kubernetes版本
> --image-repository：由于kubeadm默认是从官网 k8s.grc.io 下载所需镜像，国内无法访问，所以这里通过 --image-repository 指定为 163 镜像站
> --pod-network-cidr：指定pod网络段
> --service-cidr：指定service网络段
> --ignore-preflight-errors=Swap 将报错信息设置为Swap。当然，如果你环境配置得当，不需要它

命令行参数的方式，需要在下一步kubeadm init的时候一起执行

#### 2.3 拉取镜像

```shell
kubeadm config images pull --config=init.yaml
```

结果如下：

> [config/images] Pulled registry.aliyuncs.com/google_containers/kube-apiserver:v1.20.5
> [config/images] Pulled registry.aliyuncs.com/google_containers/kube-controller-manager:v1.20.5
> [config/images] Pulled registry.aliyuncs.com/google_containers/kube-scheduler:v1.20.5
> [config/images] Pulled registry.aliyuncs.com/google_containers/kube-proxy:v1.20.5
> [config/images] Pulled registry.aliyuncs.com/google_containers/pause:3.2
> [config/images] Pulled registry.aliyuncs.com/google_containers/etcd:3.4.13-0
> [config/images] Pulled registry.aliyuncs.com/google_containers/coredns:1.7.0

#### 2.4 初始化 master

##### 2.4.1 使用配置文件方式

```shell
kubeadm init --config=init.yaml
```

##### 2.4.2 使用命令行参数方式

```shell
kubeadm init --kubernetes-version=v1.20.5 \
             --image-repository=registry.aliyuncs.com/google_containers \
             --pod-network-cidr=192.128.0.0/24 \
             --service-cidr=10.96.0.0/12 \
            #--ignore-preflight-errors=Swap
```

结果如下：

> init] Using Kubernetes version: v1.20.5
> [preflight] Running pre-flight checks
> [preflight] Pulling images required for setting up a Kubernetes cluster[certs]
> ......
> Your Kubernetes control-plane has initialized successfully!
>
> To start using your cluster, you need to run the following as a regular user:
>
>   mkdir -p $HOME/.kube
>   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
>   sudo chown $(id -u):$(id -g) $HOME/.kube/config
>
> Alternatively, if you are the root user, you can run:
>
>   export KUBECONFIG=/etc/kubernetes/admin.conf
>
> You should now deploy a pod network to the cluster.
> Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
>   https://kubernetes.io/docs/concepts/cluster-administration/addons/
>
> Then you can join any number of worker nodes by running the following on each as root:
>
> kubeadm join 172.24.14.91:6443 --token yvhauq.sxcuhh300d5vpvhy \
>     --discovery-token-ca-cert-hash sha256:439f9df853943ead685dc63d8af0d04c32e7b9b8dc4e148e0fb41dab33997c11

出现上述信息，表示初始化完成，从上述提示中我们可以获得一下信息：

* initialize successfully 说明已经初始化完
* 集群能被正常用户正常使用，还需要执行提示中所说的内容。
* kubectl apply -f 可以让我们初始化网插件。支持网络插件可以在给出的 url 里查到
* 最后一段包含了后面我们需要使用 kubeadm join 命令将来 node 加入到集群所需要 token 等信息

但我第一次弄的时候没有这么顺利，出现了如下问题：

```shell
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.

	Unfortunately, an error has occurred:
		timed out waiting for the condition

	This error is likely caused by:
		- The kubelet is not running
		- The kubelet is unhealthy due to a misconfiguration of the node in some way (required cgroups disabled)

	If you are on a systemd-powered system, you can try to troubleshoot the error with the following commands:
		- 'systemctl status kubelet'
		- 'journalctl -xeu kubelet'

	Additionally, a control plane component may have crashed or exited when started by the container runtime.
	To troubleshoot, list all containers using your preferred container runtimes CLI.

	Here is one example how you may list all Kubernetes containers running in docker:
		- 'docker ps -a | grep kube | grep -v pause'
		Once you have found the failing container, you can inspect its logs with:
		- 'docker logs CONTAINERID'

error execution phase wait-control-plane: couldn't initialize a Kubernetes cluster
To see the stack trace of this error execute with --v=5 or higher
```

解决方案参考 [这里](https://blog.csdn.net/weixin_44789466/article/details/119046245)，配置文件中，`advertiseAddress` 一定要设置为 master 节点的 IP，否则可能出现上述问题。

##### 2.4.3 配置用户环境

以root用户为例，我们在/root/目录下执行如下命令：

```shell
#root用户的 $HOME 变量为 /root
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

这个时候，我们使用如下命令，查看一下集群节点：

```shell
kubectl get nodes
```

结果如下：

```shell
NAME         STATUS     ROLES                  AGE     VERSION
kubeadmcli   NotReady   control-plane,master   3m30s   v1.20.5
```

从输出中，我们可以发现，STATUS 还处于 [NotReady] 的状态，这是因为我们还没有初始化网络插件。

#### 2.5 初始网络插件

从安装成功的提示文本中，我们可以看到，支持的网络插件都位于：

> https://kubernetes.io/docs/concepts/cluster-administration/addons/

打开以后，我们选择 `flannel`，会跳转到 `flanne` 项目的 `github` 地址。我们选择进入到 `flannel` 项目的主目录，里面有 `flannel` 插件的使用方式。从说明中，我们可以看到 **大于1.17** 版本的k8s，使用如下`yml`文件：

> kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

> 注：如果网络不好，可以使用 wget 或者 curl 先把 yaml 文件下载下来，放到本地执行

将 yml 文件保存到本地，名为 flannel.yaml。执行如下命令初始化flannel：

```shell
kubectl apply -f flannel.yaml
```

输出如下：

```shell
podsecuritypolicy.policy/psp.flannel.unprivileged created
clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.apps/kube-flannel-ds created
```

完成以后，本地镜像会多出 flannel 的镜像：

```shell
[root@master ~]# docker images
REPOSITORY                                                        TAG                 IMAGE ID            CREATED             SIZE
...
quay.io/coreos/flannel                                            v0.13.1-rc2         dee1cac4dd20        2 months ago        64.3MB
...
```

### 3. 初始化 node

#### 3.1 安装 kubelet、kubectl 和kubeadm 

```shell
yum -y install kubelet-1.20.5 kubeadm-1.20.5 kubectl-1.20.5
```

#### 3.2 初始化 node

##### 3.2.1 命令行方式

初始化master节点的时候，从输出信息中，已经给出了初始化node节点的方式：

```sh
kubeadm join 172.24.15.212:6443 --token yvhauq.sxcuhh300d5vpvhy \
    --discovery-token-ca-cert-hash sha256:439f9df853943ead685dc63d8af0d04c32e7b9b8dc4e148e0fb41dab33997c11
```

##### 3.2.2 配置文件方式

同样，我们可以通过 `kubeadm config print` 命令输出 `init node` 节点的默认配置：

```sh
kubeadm config print join-defaults
```

输出如下：

```sh
apiVersion: kubeadm.k8s.io/v1beta2
caCertPath: /etc/kubernetes/pki/ca.crt
discovery:
  bootstrapToken:
    apiServerEndpoint: kube-apiserver:6443
    token: abcdef.0123456789abcdef
    unsafeSkipCAVerification: true
  timeout: 5m0s
  tlsBootstrapToken: abcdef.0123456789abcdef
kind: JoinConfiguration
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: kubeadmclinode02
  taints: null
```

我们主要关注如下几项，并将apiServerEndpoint、token、tlsBootstrapToken改成master节点信息。

```sh
apiVersion: kubeadm.k8s.io/v1beta2
discovery:
  bootstrapToken:
    apiServerEndpoint: 172.24.14.91:6443
    token: yvhauq.sxcuhh300d5vpvhy
    unsafeSkipCAVerification: true
  tlsBootstrapToken: yvhauq.sxcuhh300d5vpvhy
kind: JoinConfiguration
```

将上述内容保存为init_node.yaml.然后使用如下命令初始化节点：

```sh
kubeadm join --config=init_node.yaml
```

上面两种方法都出现如下输出的时候，说明正确了：

```sh
This node has joined the cluster:

- Certificate signing request was sent to apiserver and a response was received.
- The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

此时 node 上的 kubelet 也将正常运行。可能这时候你在 master 上执行 [kubelet get nodes] 的时候，该 node 还处于 NotReady 的状态，别着急，一会就回刷新过来。

### 4. 运行测试程序

#### 4.1 deployment 镜像

```sh
kubectl create deployment myapp --image=wangyanglinux/myapp:1
```

查看运行的程序：

```sh
kubectl get pod -o wide

NAME                     READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
myapp-6b6c94dd79-g9vnn   1/1     Running   0          2m27s   10.244.1.2   k8s-node01   <none>           <none>

```

#### 4.2 程序横向扩容

```sh
kubectl edit deployment myapp
// 修改 replicas 字段
replicas: 10
// :wq 保存退出
```

查看运行的程序：

```sh
kubectl get pod 

NAME                     READY   STATUS    RESTARTS   AGE
myapp-6b6c94dd79-6vbgx   1/1     Running   0          22s
myapp-6b6c94dd79-7f2vf   1/1     Running   0          22s
myapp-6b6c94dd79-8v242   1/1     Running   0          22s
myapp-6b6c94dd79-dq22w   1/1     Running   0          22s
myapp-6b6c94dd79-g2z5s   1/1     Running   0          22s
myapp-6b6c94dd79-g9vnn   1/1     Running   0          4m50s
myapp-6b6c94dd79-jbs7f   1/1     Running   0          22s
myapp-6b6c94dd79-lcdvm   1/1     Running   0          22s
myapp-6b6c94dd79-sz484   1/1     Running   0          22s
myapp-6b6c94dd79-tlcwc   1/1     Running   0          22

```

对其中一个服务，发起 curl 请求：

```sh
curl 10.244.1.2
// Wang Yang welcome you ! | Version 1 | Accessing <hostname.html> to get the current host name
curl 10.244.1.2/hostname.html
// myapp-6b6c94dd79-g9vnn
```

#### 4.3 部署一个服务

```sh
kubectl create svc clusterip myapp --tcp=8080:80
```

查看运行的服务：

```sh
kubectl get svc

NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP    30m
myapp        ClusterIP   10.98.228.65   <none>        8080/TCP   7s

```

请求该服务：

```sh
curl 10.98.228.65:8080
// Wang Yang welcome you ! | Version 1 | Accessing <hostname.html> to get the current host name
curl 10.244.1.2/hostname.html
// myapp-6b6c94dd79-tlcwc
// 多次请求，返回不同容器名称，服务进行了负载均衡
```

但现在这个服务，只能集群内部访问，外面是访问不到的，下面来解决这个问题

#### 4.4 允许外部访问服务

```sh
kubectl edit svc myapp
// 修改 type: ClusterIP 字段为 type: NodePort
type: NodePort
// :wq 保存退出
```

在看一下服务：

```sh
kubectl get svc

NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP          37m
myapp        NodePort    10.98.228.65   <none>        8080:32752/TCP   7m17s

```

myapp 服务映射出了端口，32752，这时使用集群中任一一机器 IP + 该端口，都可以访问服务

例如：

```sh
curl 192.168.10.16:32752/hostname.html
// myapp-6b6c94dd79-sz484
// 多次请求，返回不同容器名称，服务进行了负载均衡
// myapp-6b6c94dd79-8v242
// myapp-6b6c94dd79-lcdvm
```

参考 [CSDN博主「初码诛仙」 ](https://blog.csdn.net/zxycyj1989/article/details/117172414)
按照步骤搭建成功，记录下来，备忘