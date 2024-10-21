### 脚本功能：  
这个脚本用于根据指定的IP集合文件，向`ipset`中添加IPv4和IPv6地址，并利用`iptables`和`ip6tables`规则屏蔽这些IP。脚本支持三种操作模式：添加IP集合、删除IP集合以及列出所有`ipset`集合。

### 使用方法：

```bash
./ban.sh --action <操作> [--file <IP集合文件>] [--name <IP集合名称>]
```

### 参数说明：
- `--action <操作>`：必填参数，指定要执行的操作类型：
  - `add`：将IP集合文件中的IP添加到指定的`ipset`集合，并通过`iptables`和`ip6tables`屏蔽它们。
  - `delete`：删除指定的`ipset`集合，并同时解除与该集合相关的`iptables`和`ip6tables`屏蔽规则。
  - `list`：列出当前系统中所有的`ipset`集合名称。

- `--file <IP集合文件>`：当`--action`为`add`时，必填参数，指定包含IP段的文件。文件中的每一行应为一个IP段，支持IPv4和IPv6。例如：
  ```
  210.16.188.0/22
  211.152.32.0/19
  2401:3480::/36
  2404:82c0::/42
  ```

- `--name <IP集合名称>`：必填参数，指定`ipset`集合的名称。脚本会根据该名称创建IPv4和IPv6的`ipset`集合，名称格式为 `<name>_v4` 和 `<name>_v6`。

### 操作说明：

#### 1. 添加IP集合并屏蔽：
此操作将读取指定文件中的IP地址段，并添加到对应的`ipset`集合中。IPv4地址将添加到`<name>_v4`集合，IPv6地址将添加到`<name>_v6`集合。然后，通过`iptables`和`ip6tables`规则屏蔽这些IP。

**示例：**
```bash
./ban.sh --action add --file UCloud.txt --name UCloud
```

执行后：
- IPv4地址将添加到`UCloud_v4`集合。
- IPv6地址将添加到`UCloud_v6`集合。
- `iptables`将屏蔽`UCloud_v4`集合中的IP，`ip6tables`将屏蔽`UCloud_v6`集合中的IP。

#### 2. 删除IP集合并解除屏蔽：
此操作将删除指定的`ipset`集合，并同时解除`iptables`和`ip6tables`中的相关屏蔽规则。

**示例：**
```bash
./ban.sh --action delete --name UCloud
```

执行后：
- 将删除 `UCloud_v4` 和 `UCloud_v6` 两个`ipset`集合。
- 同时，解除与这两个集合相关的`iptables`和`ip6tables`屏蔽规则。

#### 3. 列出所有`ipset`集合：
此操作将列出当前系统中所有的`ipset`集合名称。

**示例：**
```bash
./ban.sh --action list
```

执行后，将显示当前系统中所有创建的`ipset`集合。

### 注意事项：
1. 脚本会自动根据IP格式（IPv4或IPv6）来决定将其添加到哪个集合中。
2. 如果集合已经存在，脚本会跳过集合创建步骤，并将IP段继续添加到已有的集合中。
3. 删除操作会同时删除与集合关联的`iptables`和`ip6tables`规则，以确保解除对这些IP的屏蔽。

### 示例：
#### 添加IP集合并屏蔽：
```bash
./ban.sh --action add --file ip_list.txt --name my_blocklist
```

#### 删除IP集合并解除屏蔽：
```bash
./ban.sh --action delete --name my_blocklist
```

#### 列出所有`ipset`集合：
```bash
./ban.sh --action list
```

### IP集合文件的获取方法

#### 1. 通过 [ipdeny.com](https://www.ipdeny.com/ipblocks/) 下载区域IP
[ipdeny.com](https://www.ipdeny.com/ipblocks/data/countries/) 提供全球各国家/地区的IP集合。选择对应国家的文件下载，例如 [美国IP段](https://www.ipdeny.com/ipblocks/data/countries/us.zone)。

示例：
```
3.0.0.0/8
4.0.0.0/9
```

#### 2. 通过 [whois.ipip.net](https://whois.ipip.net/) 搜索ASN
在 [whois.ipip.net](https://whois.ipip.net/) 搜索服务商的ASN号（如`DIGITALOCEAN`），获取该ASN的IP段。

#### 3. 使用ASN编号查询
通过 `ASN.md` 文件查找厂商ASN编号。例如：
```
### DIGITALOCEAN
- 14061 DIGITALOCEAN-ASN - DigitalOcean, LLC, US
```
利用ASN号在`whois`等工具中查询对应IP段。

#### 4. 合并IP段
可以通过 [cidr-merger](https://github.com/zhanhb/cidr-merger) 项目合并IP段，减少重复和简化输出。

**示例：**
```bash
./cidr-merger --merge -o ip_new.txt ip.txt
```

这会将`ip.txt`中的IP段合并后输出到`ip_new.txt`。