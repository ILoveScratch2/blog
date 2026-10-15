---
title: "Linux 又双叒叕出提权漏洞：Dirty Frag"
date: 2026-05-10 21:50:10 +0800
categories: [技术, 闲聊]
tags: [Luogu, AI, Code]
math: true
---

某天，在~~水谷~~写 ~~C with Classes~~ C++ 代码的时候，打了 `#in`，Tab 一按，`#include` 就出来了。

![](https://cdn.luogu.com.cn/upload/image_hosting/ygcgoq28.png)

光标停着没动，Copilot（是的，就是 GitHub 的那个）又把下面三行全补了出来，还补对了。

![](https://cdn.luogu.com.cn/upload/image_hosting/3gaac59s.png)

写这个专栏的时候打字 `zhuanlan`，输入法又补成了 `专栏` 这两个字。

![](https://cdn.luogu.com.cn/upload/image_hosting/mastouy2.png)

~~这就是传说中的全自动吗？~~

同样是“少打几个字”，这两件事很不一样~~一个算比赛作弊一个不算~~，但没准其实是同一件事？

## 一个公式

补全不管是哪个场景，都是一样的：**触发、检索、排序**。

$$
\text{candidates}(c, p) = \text{rank}(\text{retrieve}(c, p))
$$

设 $c \in \mathcal{C}$ 表示 local context，$p \in \mathcal{P}$ 表示 trigger pattern。系统先用 retrieve 从候选源里捞一批结果出来，再用 rank 排个序，把最像你想要的那个放前面。

- 触发：什么时候弹候选？LaTeX 里是字母前缀加 Tab，IDE 里是 `.`/`(`/`::`/`#`，Copilot 任意停顿都能触发。
- 候选源：能力上限在哪里？最简的是一个静态文件，IDE 是符号表，Copilot 是语言模型。
- 排序：第一个候选是什么？中文输入法靠词频，IDE 靠类型匹配，Copilot 靠模型概率分布。

这套框架其实很多年都没怎么变。真正在变的，可能只是 $c$ 能塞进去多少上下文，以及 retrieve 到底能做得多复杂。

---

像 LaTeX 里的 `\bal` 展开，或者 C++ 里 `#include` 这种自动补出，本质上都算最朴素的一类补全。

候选源就是一张 snippet 表，检索方式就是前缀匹配。命中了以后，再按 TextMate 的那套语法去展开 `$1`、`$0` 这些 tab stop。

![](https://cdn.luogu.com.cn/upload/image_hosting/ph1ihcba.png)

这套语法最早来自 2005 年的 TextMate 1.1 beta，作者是 Allan Odgaard。他定义了 `$1 $2 ... $n` 这种跳位标记，`${1:default}` 这种带默认值的占位符，还有 `${1/regex/replace/}` 这种正则替换。`$0` 则表示最后退出的位置。

后来的 VS Code、Vim 的 UltiSnips、Emacs 的 YASnippet，基本都把这套东西原样接过去了。[VS Code 文档](https://code.visualstudio.com/docs/editing/userdefinedsnippets)自己也写得很直接：

> Snippets support most TextMate syntax.

题外话：Odgaard 后来承诺的 TextMate 2 一拖就是五年。2012 年他把 TextMate 2 在 GPL-3 下直接开源，作为对 Mac App Store 限制的抗议。开源直接把 snippet 语法生态彻底锁定为跨编辑器标准，今天写 LaTeX 敲的每个 snippet 展开，跑的是 2005 年的语法。

输入法里的自定义短语，其实也是差不多的思路。

一张用户级别的 abbreviation 表，在拼音解码之前先做一遍前缀匹配，命中直接出。整句联想那一层才走 $N$-gram 加 Viterbi（平滑一般用 Modified Kneser-Ney，理论上是非神经语言模型的天花板平滑方案），两条路径是独立的。

## 前缀检索

前缀检索的标准答案是 Trie，或者说字典树。[想必作为 OIer 你大概听过](https://oi-wiki.org/string/trie/)，应该也是你第一个想到的。


在你谷也有[文章](https://www.luogu.com.cn/article/oufbmjvb)讲过，就不重复解释 Trie 了。

它的查询复杂度是 $\mathcal{O}(L)$。设 $L \in \mathbb{N}$ 表示查询串长度。也就是说，它和字典里一共有多少词，其实没直接关系。snippet 库里是一百个词也好，一百万个词也好，只要前缀长度一样，查起来的量级就差不多。

:::info[30 行朴素 Trie]{open}
```python
class Trie:
    def __init__(self):
        self.children, self.is_end = {}, False

    def insert(self, word):
        node = self
        for ch in word:
            node = node.children.setdefault(ch, Trie())
        node.is_end = True

    def autocomplete(self, prefix):
        node, results = self, []
        for ch in prefix:
            if ch not in node.children:
                return results
            node = node.children[ch]
        def dfs(n, path):
            if n.is_end:
                results.append(path)
            for c, nxt in n.children.items():
                dfs(nxt, path + c)
        dfs(node, prefix)
        return results
```
:::

当然，工程里一般不会真就这么直接上这个朴素版本。原因也简单，指针开销挺大，内存不太扛得住。所以实际更常见的是一些压缩变种：

- **双数组 Trie**（DAT）：用两个一维数组 BASE 和 CHECK 来表示状态机。查找时每个字符还是 $\mathcal{O}(1)$，但空间会比朴素实现省很多。
- **MARISA-trie**：这个更狠一点，基于 succinct 数据结构。比如 300 万词的词典，如果你直接用 Python `dict`，可能要吃掉 600 MB；MARISA 大概只要 7 MB。

不过 Trie 也有个很明显的限制，就是它只擅长处理“前缀真的打对了”的情况。比如你输 `nh`，想找 `ni hao`，那普通 Trie 就没法直接帮你了。

所以现代编辑器一般不会只做前缀匹配，还会额外加一层**模糊匹配评分**。

VS Code、Sublime Text 这一类工具用的模糊匹配算法，往上追的话，大多能追到 1981 年的 Smith-Waterman 局部序列对齐。这个算法原本其实是做 DNA 比对的。fzf 作者自己也在源码注释里提过，v2 算法是 Smith-Waterman 的一个变种，只允许 gap，不允许 mismatch。

具体评分细节各家不完全一样，但启发式大体差不多：连续匹配会加分，词边界会加分，CamelCase 里的大写字母会加分，没匹配上的字符会扣点分。大概就是这么一套。

## LSP（是 Language Server Protocol！）

2016 年之前，设 $N \in \mathbb{N}$ 表示编辑器数量，$M \in \mathbb{N}$ 表示语言数量，那么高亮和补全这套能力，基本就得做 $N \times M$ 遍。也就是每个编辑器都得实现一遍解析器，语法解析规则还可能有细微的差别。

**语言服务器协议**，也就是 LSP，是微软、Red Hat、Codenvy 在 2016 年 6 月一起发出来的。

它最核心的价值很直接：编辑器这边把客户端实现一次，语言这边把服务端实现一次，就不用再硬连解析器了。

![网图](https://cdn.luogu.com.cn/upload/image_hosting/svw2kpyu.png)

协议本身走的是 JSON-RPC 2.0。你在编辑器里触发补全的时候，客户端大概会给 server 发这样一个请求：

```json
{
  "method": "textDocument/completion",
  "params": {
    "textDocument": { "uri": "file:///paper.tex" },
    "position": { "line": 12, "character": 8 },
    "context": { "triggerKind": 2, "triggerCharacter": "\\" }
  }
}
```

server 算完之后会回一个 CompletionList，里面每一项都是 CompletionItem，比如：

```json
{
  "label": "begin",
  "kind": 14,
  "insertText": "begin{$1}\n\t$0\n\\end{$1}",
  "insertTextFormat": 2
}
```

这里 `kind: 14` 表示它是 Snippet，`insertTextFormat: 2` 表示插入文本要按 TextMate snippet 语法解析，也就是前面说的那套 `$1`、`$0` 规则。

:::warning[sortText 不一定管用]{open}
LSP 里 server 可以给每个候选设置 `sortText` 指定排序。但 VS Code 的实际优先级是：先按模糊匹配分排，再看 `preselect` 标志，最后才是 `sortText`。也就是说 server 的排序，客户端可以直接推翻。
:::

另外，虽然都叫 LSP server，不同实现之间差别也是不少的。

clangd 是基于 Clang AST 做的，里面一个很关键的设计叫 Preamble Cache。简单说，就是把那些 `#include` 带来的预编译结果缓存下来，以后只重解析当前主文件。像 Chromium 这种几百万行的大项目，第一次打开可能要等一会儿，但后面的补全能压到毫秒级，主要就靠这个缓存。

rust-analyzer 走的是另一条路线。它没有直接依赖 rustc 的前端，而是自己做了一套更偏 IDE 场景的 frontend，再用 Salsa 这种增量计算框架去做查询缓存。两边都在做补全，也都挂着 LSP 的接口，但其实差得挺远。

## 代码高亮

补全回答的是“下一个 token 可能是什么”，高亮回答的是“当前这个 token 到底是什么”。问题不一样，但底层基础设施又确实有不少重叠。

传统高亮主要靠**正则语法**。还是 TextMate：`.tmLanguage` 文件用正则把 token 切成不同 scope，再由主题把 scope 映射成颜色。VS Code、Sublime Text 这些编辑器基本都继承了这个体系。你随便装个语言扩展，里面大概率还能翻到 `.tmLanguage`。

问题在于，正则其实不太擅长处理嵌套结构。C++ 模板、宏、多行字符串，这些东西都很容易把正则高亮搞乱。更麻烦的是，每次敲键盘都可能要重新跑一遍规则。你改一行，后面几百行的高亮可能都跟着飘。

但正则写不了嵌套结构。C++ 模板、宏、多行字符串，都能让正则高亮出现错位。更烦的是每次按键都要重新跑一遍，改一行可能让后面几百行高亮全乱。

2018 年 10 月，GitHub Atom 团队的 Max Brunsfeld 开源了 tree-sitter。核心想法：用真正的语法解析器代替正则，给编辑器一棵随时可用的**增量语法树**（CST）。改一个字符只更新受影响的子树，不重新解析整个文件。而且**代码有语法错误也能产出可用的树**。你正在打的 `int x =` 还没打完，tree-sitter 还是给你一棵带错误节点的 CST，高亮不会因为代码没写完就没颜色了。

有了 CST 之后，高亮这件事就更像是在树上做查询，而不是拿一堆正则去扫文本：

```
(function_definition
  name: (identifier) @function.name)

(call_expression
  function: (identifier) @function.call)
```

这些像 `@function.name` 一样的捕获结果，再映射成颜色。这样做通常会比纯正则更准，也更稳。

[隔壁专栏](https://www.luogu.com.cn/article/enyj16u1)也是使用 tree-sitter 解析语法。



:::warning[tree-sitter 不做补全]{open}
它只解析语法层（给你 CST），不做类型推断，不做跨文件分析。

所以一般来说，高亮靠 tree-sitter，补全还是靠 LSP server。

![](https://cdn.luogu.com.cn/upload/image_hosting/edgb99op.png)
:::

当然，tree-sitter 在补全链路里也不是完全没存在感。比如 Cursor 做向量索引时，会用它来做**语义切片**。也就是按函数、类、方法这种语法边界把文件切成 chunk，再把这些 chunk 丢去做 embedding。

这么切的好处很实际：一个函数体通常是一个完整语义单元。如果你只是按固定行数硬切，很可能正好从函数中间一刀砍开，检索质量就容易掉。

## Fill-in-the-Middle

前面讲的基本都是偏确定性的补全。那 Copilot 这种模型补全呢？

传统语言模型通常只能从左往右生成。也就是说，你给它一个 prefix，它往后续写 suffix。但真实写代码的时候，光标常常停在一个函数中间。前面有 prefix，后面其实也已经有 suffix 了。这时候模型要做的不是一路写到文件末尾，而是**把中间缺的那块补上**。

这就是 FIM，也就是 Fill-in-the-Middle。

它的训练数据构造思路并不复杂。大概就是把一篇文档随机切成三段，然后换一种特殊顺序喂给模型：

$$[\text{prefix token}]\ \underbrace{P}_{\text{Prefix}}\ [\text{suffix token}]\ \underbrace{S}_{\text{Suffix}}\ [\text{middle token}] \Rightarrow \underbrace{M}_{\text{Middle}}$$

相关论文里一个很核心的结论是：当 FIM 训练比例拉到 $90\%$ 左右时，模型在标准左到右生成任务上的表现，并不会明显输给纯自回归模型，同时还额外学会了中间填空的能力。


## 光标看不见的地方

不过只有 FIM 其实还不够。

因为光标前后能直接看到的上下文，往往也就几百行。可你现在调用的那个函数，定义很可能躺在另一个文件里。Copilot 这类系统要真想补得像样，就得去找光标之外的相关内容。

Copilot 早期一个比较经典的做法，是扫描当前打开的标签页，对每个文件做大约 60 行的滑动窗口切片，然后用 Jaccard 相似度，也就是 token 集合重叠比例，去给这些 chunk 打分，再把高分结果拼进 prompt。

这里有个现象还挺有意思：哪怕最高分 chunk 看起来也没那么相关，把它塞进去，效果通常还是比完全不塞要好。模型似乎有一定能力自己判断哪些信息是噪声，不太会轻易被带偏。

说到“怎么给模型提供上下文”，现在主流工具大概走了两条路。

- Cursor（就是很火的那个）用的是 RAG，直接给模型做向量索引，节省 Token，但是模型不一定能用 RAG 找到需要的数据（即使存在）。
- Claude Code（还是不知道为什么这么火）不一样，根本不做向量索引，直接给模型一组工具：读文件、grep、执行命令，让模型自己决定看什么。依赖长上下文把读到的内容全装进去。代价是单次 session 的 token 成本可能是 RAG 方案的几倍。

也可以结合长上下文和语义检索，增加效率，如 Copilot 的 Index：

![](https://cdn.luogu.com.cn/upload/image_hosting/1w7t1be8.png)

从五笔字型的 25 个键，到跑在 GPU 集群上的代码模型，这条链路延伸了四十年。公式 $\text{rank}(\text{retrieve}(c, p))$ 没变，$c$ 从几个字符扩展到了无数文本，retrieve 从静态码表进化成了神经网络。

但补全系统做的事一直都是**猜你接下来想表达什么**。并帮你准备好。