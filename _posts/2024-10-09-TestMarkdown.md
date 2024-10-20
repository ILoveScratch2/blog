---
title: Testing Markdown
date: 2024-10-20 16:30:00 +0800
categories: [Blog]
tags: [Blog, test]
---

# Markdown测试

## 1. 文本测试


标题测试:


# 标题测试
## 标题测试
### 标题测试
#### 标题测试
##### 标题测试
###### 标题测试

 

列表测试

- 列表项 1
- 列表项 2
  - 嵌套列表项 1
  - 嵌套列表项 2

## 2. 链接和图片

[这是一个链接](https://www.example.com)

![这是一个图片](https://via.placeholder.com/150)

## 3. 数学公式

测试:
$$
E = mc^2
$$


### 1. 行内公式

$E = mc^2$

### 2. 块级公式

$$
\int_0^1 x^2 \, dx = \frac{1}{3}
$$

### 3. 其他公式示例

- 斐波那契数列的定义：

$$
F(n) = F(n-1) + F(n-2)
$$

- 复数的极坐标表示：

$$
z = r(\cos \theta + i \sin \theta)
$$


## 4. 引用

> 这是一个引用示例。

## 5. 代码块


Python
```python
import os

def hello_world():
    print("Hello World!")


if __name__ == "__main__":
    hello_world()

```

C++
```cpp
#include <iostream>
using namespace std;


int main()
{
    cout<<"Hello World!";
    return 0;
}
```

C
```c
#include <stdio.h>


int main()
{
   printf("Hello World!");
   return 0;
}
```
Batch
```batch
echo Hello World!
```
C#
```csharp
using System;

public class Program
{
    public static void Main(string[]args)
    {
        Console.WriteLine("Hello World!");
    }
}
```
HTML
```html
<!DOCTYPE html>
<html>

<head>
    <title>HTML Hello World</title>
</head>

<body>
    <p>Hello World!</p>
</body>

</html>
```
Bash
```bash
#!/bin/bash
# This is a first demo, echo helloworld.
:<<EOF
EOF
str="Hello, World!"
echo $str
```
