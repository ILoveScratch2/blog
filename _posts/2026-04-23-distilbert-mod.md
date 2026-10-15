---
title: "用 DistilBERT 做一个内容审核 AI 模型"
date: 2026-04-23 12:12:11 +0800
categories: [技术, AI]
tags: [开源, Luogu, AI]
math: true
---
需要检测用户输入文本的场景很多，比如说（当你要做）：评论区、论坛、聊天室……等等。

如果直接不做任何处理，平台做大了各种广告显然就会肆无忌惮地刷屏，影响用户体验，某些内容还可能是违法违规的。~~被找上门责令改正并罚款就完蛋了。~~

~~其实这个文章的主要写作目的是我自己想做聊天室系统，要检测内容……~~

显然，你没那个能力去做人工审核（用户发个帖子等几十分钟才能审核完发出去？）需要自动判断哪些正常、哪些不正常。

正则？关键词匹配？

简单场景~~应该也许可能~~能用，但文本有变化就不行了。规则是写不完的，维护词表的难度也很大。

而且有的词汇单独出现时可能无害，但和其他词组合在一起就成了其他意思，通杀就太严格了，放任不管又太宽松了。

AI 模型能不能会这些复杂的关系？

所以我打算弄一个模型，能自己从标注数据里学规律。

经过和 DeepSeek 的一番友好选型交流，最后我选用了 HuggingFace 的 **DistilBERT** 预训练模型来搭建审核 AI。


## DistilBERT 的内部结构

### Transformer 层与自注意力

DistilBERT 的核心是 Transformer 架构。

Transformer 之所以能理解输入的文本，依赖的是自注意力机制。

自注意力让每个 token 在编码时都能看到序列里的所有其他 token，而不是像那些 RNN 那样逐字顺序处理。

具体来说，给定一个 token 序列，自注意力把每个 token 的向量映射成三个向量：**查询（$Q$）**、**键（$K$）**、**值（$V$）**。然后对于 token $i$，它的输出是序列中所有 token 的 $V$ 的加权和，权重由 $Q$ 和 $K$ 的点积决定：

$$
\text{Attention}(Q, K, V) = \text{softmax}\!\left(\frac{QK^\top}{\sqrt{d_k}}\right) V
$$

其中，$d_k$ 是向量维度；除以 $\sqrt{d_k}$ 是为了防止点积过大，导致 $\operatorname{softmax}$ 的梯度过小。权重向量经过 $\operatorname{softmax}$ 后会变成概率分布，表示“我在理解当前 token 时应该把注意力放在哪些位置上”。

DistilBERT 使用**多头注意力（Multi-Head Attention）**，也就是说 DistilBERT 把上面的过程并行做 $12$ 次，每个头用不同的 $W_Q$、$W_K$、$W_V$ 投影矩阵，学习不同类型的关注关系（有的头关注句法，有的头关注语义）。$12$ 个头的输出拼接后再做一次线性变换，得到最终的注意力输出。

每个 Transformer 层的完整结构是：

$$
\text{output} = \text{LayerNorm}\big(\text{FFN}(\text{LayerNorm}(x + \text{MultiHeadAttn}(x)))\big)
$$

也就是：
$$
\text{Attn} \rightarrow \text{Residual} \rightarrow \text{LayerNorm} \rightarrow \text{FFN} \rightarrow \text{Residual} \rightarrow \text{LayerNorm}
$$

残差连接保证梯度能顺畅地反向传播穿过多层网络。

### DistilBERT

满血原版 BERT-base ~~高达~~有 $12$ 个 Transformer 层，隐层维度为 $768$，总参数约为 $1.1 \times 10^8$。

DistilBERT 把层数砍到 $6$ 层，维度保持为 $768$。参数量从 $1.1 \times 10^8$ 降到 $6.6 \times 10^7$，比直接用 BERT 快不少，毕竟~~家没矿~~没那么多算力。

BERT 在每条输入序列的开头插入一个特殊的 `[CLS]`（classification）token。这个 token 没有实际词义，但经过 $6$ 层 Transformer 后，它的隐状态向量会通过注意力机制聚合整个序列的语义信息。分类任务就是取这个 `[CLS]` 位置的 $768$ 维向量，送进分类头。


（另一个特殊 token 是 `[SEP]`，用于分隔两段文本，现在的内容识别只有一段在句尾。）

## 项目

我用了 `distilbert-base-multilingual-cased` 模型，支持 $104$ 种语言（包括中文）。

源代码可在 [GitHub](https://github.com/ILoveScratch2/Content-Moderation) 获取。`train.py` 是训练脚本，`predict.py` 是运行脚本，模型文件可以在 [GitHub Releases](https://github.com/ILoveScratch2/Content-Moderation/releases/tag/model) 下载。

数据我选择了 [Olivi-9/Chinese-Spam-Dataset](https://github.com/Olivi-9/Chinese-Spam-Dataset/) 进行测试，其中的格式是两列 CSV：

```csv
label,text
0,"正常文本"
1,"广告文本"
```

其中，$0$ 表示正常，$1$ 表示敏感。

后续，我又选择了 [Chinese-Offensive-Language-Dataset](https://github.com/royal12646/Chinese-offensive-language-detect/) 中的 `SexHarmSet` 和 `AbuseSet` 数据集并与前面的数据集合并进行测试，其中的格式是三列 CSV：

```csv
Keyword,Type,Sentence
XX,Safe,正常内容
XX,Harmful,敏感内容
```

为了方便训练，后面我把这两种格式的 CSV 转成统一的 `label,text` 格式（丢弃了 `Chinese-Offensive-Language-Dataset` 中的 `Keyword` 字段），并合并成一个新的数据集。


## 环境准备

```bash
pip install torch transformers pandas scikit-learn accelerate
```

如果有 CUDA GPU，确保先装了对应版本的 PyTorch（去 [pytorch.org](https://pytorch.org/) 按你的 CUDA 版本选）不然默认安装只能用 CPU。

~~CPU 也能训练就是极慢无比。~~

---

## 训练流程

### 1. 加载和切分数据

```python
import pandas as pd
from sklearn.model_selection import train_test_split

df = pd.read_csv("train.csv")
train_texts, val_texts, train_labels, val_labels = train_test_split(
    df["text"].tolist(),
    df["label"].tolist(),
    test_size=0.2,
    random_state=42,
    stratify=df["label"],  # 保持正负比例
)
```

`stratify` 主要是防止正负样本比例不均衡，随机切分可能导致集里某一类占比太多/太少力。加了 `stratify` 后每个子集都保持原始比例。

对于数据不均衡的情况，见下文的处理数据部分。

### 2. 分词编码

包括 DistilBERT 在内的 Transformer 模型（是的，AIer 爱用的 LLM 也是 Transformer 模型）都不能直接处理文本，需要先用 Tokenizer 把文字转成 token ID 序列。

这里用的分词算法是 WordPiece，是一种子词切分方案。

先解释一下为什么要用子词分词。如果词表是整词级别的（像中文词那样），碰到生僻词、变形词就直接变成未知。

如果词表是字符级别的，词表很小，但序列会很长，理解更难。

WordPiece 把高频词保留为完整单元，把低频词拆成更小的子词片段，用 `##` 前缀标记“这是上一个词的延续”。

例如：

```python
from transformers import DistilBertTokenizerFast

tokenizer = DistilBertTokenizerFast.from_pretrained("distilbert-base-multilingual-cased")

enc = tokenizer("来加我微信，加我可以领取 EXAMPLE 优惠券", return_tensors="pt")

print(enc["input_ids"])
# tensor([[  101,  4501,  2598,  3976,  3785,  2316, 10064,  2598,  3976,  2756, 2204,  8427,  2737, 80426, 36535, 11127, 51036,  2224,  3887,  2558,  102]])

print(tokenizer.convert_ids_to_tokens(enc["input_ids"][0]))
# ['[CLS]', '来', '加', '我', '微', '信', '，', '加', '我', '可', '以', '领', '取', 'EX', '##AM', '##P', '##LE', '优', '惠', '券', '[SEP]']
```

序列开头是 `[CLS]`（ID 为 $101$），结尾是 `[SEP]`（ID 为 $102$）。这两个特殊 token 是模型要求的格式，训练和推理都必须有。

中文字符基本上每个字是一个 token（多语言 BERT 模型对中文基本上是字级别切分），到了英文是 subword 级别。

批量 tokenize 时，`padding=True` 会把同一 batch 里所有序列 pad 到相同长度，并生成 `attention_mask`，其中 $1$ 表示真实 token，$0$ 表示 padding 位置。模型在做注意力计算时，padding 位置的注意力分数会被设为 $-\infty$；经过 $\operatorname{softmax}$ 后，对应权重会趋近于 $0$，不参与实际计算。

```python
from transformers import DistilBertTokenizerFast

MODEL_NAME = "distilbert-base-multilingual-cased"
tokenizer = DistilBertTokenizerFast.from_pretrained(MODEL_NAME)

train_encodings = tokenizer(train_texts, truncation=True, padding=True, max_length=256)
val_encodings = tokenizer(val_texts, truncation=True, padding=True, max_length=256)
```

`max_length=256`：广告文本通常不长，$256$ 个 token 足够覆盖。如果你的文本特别长可以调大，但不能超过 $512$，$512$ 是 DistilBERT 位置编码的硬上限（位置编码只预训练了 $512$ 个位置，超过就没学过）。

### 3. 包装成 Dataset

PyTorch 的训练循环靠 `DataLoader` 来管理数据：自动打乱顺序、按批大小切批次、多进程预加载。`DataLoader` 要求传入一个实现了 `__getitem__(idx)` 和 `__len__()` 的 `Dataset` 对象。前者按索引返回单条样本，后者告诉它数据集有多大。HuggingFace 的 `Trainer` 内部正是用 `DataLoader` 消耗数据的，所以我们要把编码结果套进这个格式。

`__getitem__` 里做了一件关键的事：`torch.tensor(val[idx])` 把 tokenizer 输出的 Python 列表（`input_ids[i]`、`attention_mask[i]` 等）即时转成 PyTorch tensor。不在这里转的原因是把整个数据集一次性转成 tensor 会大量占内存，按需转换更合理。

```python
import torch
from torch.utils.data import Dataset

class TextDataset(Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels

    def __getitem__(self, idx):
        item = {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
        item["labels"] = torch.tensor(self.labels[idx])
        return item

    def __len__(self):
        return len(self.labels)

train_dataset = TextDataset(train_encodings, train_labels)
val_dataset = TextDataset(val_encodings, val_labels)
```

`DataLoader` 的 `collate_fn`（批次拼接函数）负责把 `__getitem__` 返回的多个样本字典拼成一个批次字典，`input_ids` 的形状会从 $\left[\text{seq\_len}\right]$ 变成 $\left[\text{batch\_size}, \text{seq\_len}\right]$，其他字段同理。`Trainer` 使用默认的 `collate_fn`，已经支持了这个格式，不需要我们手动写。

### 4. 前向传播

一条样本进入模型：

#### Embedding

`input_ids`（整数序列）通过嵌入矩阵查表，变成 token 向量序列，每个 token 映射到 $768$ 维的稠密向量。同时加上位置编码，同样学来的 $768$ 维向量，告诉模型每个 token 在序列中的位置信息（因为自注意力本身不感知顺序，位置信息必须显式注入）。两者相加：

$$h_0 = \text{TokenEmbedding}(x) + \text{PositionEmbedding}(\text{pos})$$

#### $6$ 层 Transformer

$h_0$ 经过 $6$ 个 Transformer 层，每层包含 Multi-Head Self-Attention 和 FFN（如前所述）。每层的输出形状都是 $\left[\text{batch\_size}, \text{seq\_len}, 768\right]$。经过 $6$ 层后得到 $h_6$，里面每个位置的向量都已经充分看过序列里所有其他位置的信息。

#### 取 [CLS] 位置

取 $h_6[:, 0, :]$，即每个样本 `[CLS]` 位置的 $768$ 维向量，其形状为 $\left[\text{batch\_size}, 768\right]$。

#### 分类头

$$
\left[\text{batch\_size}, 768\right] \xrightarrow{\text{Linear}(768,768)} \xrightarrow{\text{GELU}} \xrightarrow{\text{Dropout}} \xrightarrow{\text{Linear}(768,2)} \left[\text{batch\_size}, 2\right]
$$

GELU 是一种激活函数，表现优于 ReLU（细节不展开了）。最终输出的原始分数向量记作 $\boldsymbol{z}$，其形状是 $\left[\text{batch\_size}, 2\right]$；两列分别对应“正常”和“敏感”的原始分数，数值范围是任意实数。

这就是 `model(**inputs)` 返回的 `outputs.logits`。

### 5. 损失函数

模型输出的原始分数 $\boldsymbol{z}$ 形状为 $\left[\text{batch\_size}, 2\right]$，真实标签的形状为 $\left[\text{batch\_size}\right]$（每个值是 $0$ 或 $1$）。**交叉熵损失**会把这两者结合成一个标量 $\mathcal{L}$，告诉优化器当前预测离答案有多远。

先对 $\boldsymbol{z}$ 做 $\operatorname{softmax}$ 得到概率分布，再对真实类别的概率取 $\log$，最后取负均值：

$$\mathcal{L} = -\frac{1}{N} \sum_{i=1}^{N} \log p(y_i \mid x_i)$$

如果模型对正确答案的置信度是 $0.99$，$-\log(0.99) \approx 0.01$，那么 $\mathcal{L}$ 很小；如果置信度只有 $0.01$，$-\log(0.01) \approx 4.6$，那么 $\mathcal{L}$ 很大。交叉熵的梯度会推着模型把正确类别对应的分数调大、错误类别对应的分数调小。

在代码里，`DistilBertForSequenceClassification` 内部已经封装好了 CrossEntropyLoss。

如果调用时传入了 `labels`，它会自动计算损失值，并放在 `outputs.loss` 里。`Trainer` 就是拿这个损失值做反向传播的。

### 6. 反向传播

有了损失值 $\mathcal{L}$，就可以做反向传播啦！

用链式法则把 $\mathcal{L}$ 对模型每个参数的梯度 $\nabla_\theta \mathcal{L}$ 算出来。PyTorch 的 `autograd` 系统在前向传播时已经记下了整个计算图，调用 `loss.backward()` 就能自动完成。

然后是参数更新，`Trainer` 默认用 **AdamW** 优化器。AdamW 是 Adam 加权衰减的修正版本：

- **Adam** 的核心是对每个参数维护两个动量：一阶动量 $m$（梯度的指数移动平均）和二阶动量 $v$（梯度平方的指数移动平均）。参数更新量是 $m / \sqrt{v}$，梯度方向一致的维度更新快，梯度震荡的维度更新慢。这让 Adam 不需要精细调学习率就能收敛得很好。
- **AdamW 的修正**：原始 Adam 的 $L_2$ 正则化（weight decay）加在梯度里，和动量耦合在一起，效果不对。AdamW 把 weight decay 从梯度中剥离，单独作用于参数本身：$\theta \leftarrow \theta - \alpha \cdot \Delta\theta - \lambda \theta$。这样正则化效果更干净，防止过拟合效果更好。

`TrainingArguments` 里的 `weight_decay=0.01` 对应的就是这里的 $\lambda$。（注意：Embedding 层和偏置项通常不做 weight decay，HuggingFace 已经内置了这个区分逻辑。）

### 7. 学习率调度

微调预训练模型时，学习率不能一开始就冲太猛的，因为预训练权重已经在合适的位置了，大的梯度更新还会把它推偏。

`Trainer` 默认用两段式调度：

1. **Warmup（热身）**：设总训练步数为 $T$，`warmup_ratio` 记为 $r \in (0,1)$，那么前 $rT$ 步里，学习率会从 $0$ 线性升到设定值（默认 $5 \times 10^{-5}$）。
2. **线性衰减**：此后学习率从峰值线性降到 $0$。

例如当 `warmup_ratio=0.1` 时，就有 $r = 0.1$，也就是前 $10\%$ 的步数用于热身。

### 8. Trainer

```python
from transformers import DistilBertForSequenceClassification, Trainer, TrainingArguments
import numpy as np
from sklearn.metrics import accuracy_score, precision_recall_fscore_support

model = DistilBertForSequenceClassification.from_pretrained(MODEL_NAME, num_labels=2)
```

`from_pretrained(MODEL_NAME, num_labels=2)` 加载了预训练好的 DistilBERT 权重，然后在顶部接了一个新的全连接分类头。

分类头是随机初始化的，需要从头学。底层 Transformer 的权重是预训练好的，训练时也会更新，但学习率很小（默认 $5 \times 10^{-5}$），只是稍微改一改，让它更贴合当前任务，而不会把语言理解能力给训没了。**恭喜你，发现了“微调”。**（这就是一种微调。）

然后定义评估函数。

这里记真正例、假正例、假反例分别为 $\mathrm{TP}$、$\mathrm{FP}$、$\mathrm{FN}$。

- **Precision（精确率）**：记作 $P = \dfrac{\mathrm{TP}}{\mathrm{TP} + \mathrm{FP}}$，表示模型判定为“敏感”的样本里，真正是敏感的比例。$P$ 低就代表误杀太多。
- **Recall（召回率）**：记作 $R = \dfrac{\mathrm{TP}}{\mathrm{TP} + \mathrm{FN}}$，表示真正敏感的样本里，模型成功找出来的比例。$R$ 低，说明漏网之鱼太多。
- **$F_1$**：定义为 $F_1 = \dfrac{2PR}{P + R}$，是 $P$ 和 $R$ 的调和平均；两边哪个低，都会把 $F_1$ 拉下去。

具体选哪个当主指标还是要看场景：更怕漏判就看 $R$，更怕误杀就看 $P$。用 $F_1$ 作为标准，就能权衡一下。

```python
def compute_metrics(pred):
    labels = pred.label_ids
    preds = np.argmax(pred.predictions, axis=-1)
    precision, recall, f1, _ = precision_recall_fscore_support(labels, preds, average="binary")
    acc = accuracy_score(labels, preds)
    return {"accuracy": acc, "f1": f1, "precision": precision, "recall": recall}

training_args = TrainingArguments(
    output_dir="./results",
    num_train_epochs=3,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=64,
    warmup_ratio=0.1,
    weight_decay=0.01,
    logging_dir="./logs",
    logging_steps=10,
    eval_strategy="epoch",
    save_strategy="epoch",
    load_best_model_at_end=True,
    metric_for_best_model="f1",
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=val_dataset,
    compute_metrics=compute_metrics,
)

trainer.train()
```

几个参数值得说一下：

- `num_train_epochs=3`：微调预训练模型一般 $2 \sim 5$ 轮就够。太多会过拟合，让 AI 把训练集的噪声也背下来了。如果有 $F_1^{(3)} < F_1^{(2)}$，`load_best_model_at_end` 会自动回滚到第 $2$ 轮的权重。
- `per_device_train_batch_size=16`：每个 GPU 上每步处理 $16$ 条样本。太小梯度估计噪声大，太大显存不一定够。~~当然后面用 T4 GPU 的时候这个 $16$ 还是开小了。~~
- `warmup_ratio=0.1`：前 $10\%$ 的训练步数做学习率热身，前面讲过了。
- `weight_decay=0.01`：AdamW 的 $\lambda$ 参数，帮助正则化。
- `eval_strategy="epoch"` + `save_strategy="epoch"`：每轮训练结束时评估一次，并保存一个检查点。`load_best_model_at_end=True` 配合使用，训练结束后会自动加载 $F_1$ 最高的那次检查点。
- `logging_steps=10`：每 $10$ 个训练步记录一次损失值到日志，用 TensorBoard 可视化训练曲线：`tensorboard --logdir ./logs`。

训练完，保存模型和分词器：

```python
trainer.save_model("./best_model")
tokenizer.save_pretrained("./best_model")
```

---

## 推理预测

模型训练好了，拿来用。推理和训练的前向传播路径完全一样，区别只有两点：第一，不需要计算损失值（不传 `labels`）；第二，不需要维护计算图（用 `torch.no_grad()` 关闭梯度）。

`model.eval()` 切换到推理模式，关闭 Dropout。训练时的 Dropout 会随机屏蔽 $20\%$ 的神经元来防止过拟合，推理时应该让所有的参数都参与计算。

```python
from transformers import DistilBertTokenizerFast, DistilBertForSequenceClassification
import torch

tokenizer = DistilBertTokenizerFast.from_pretrained("./best_model")
model = DistilBertForSequenceClassification.from_pretrained("./best_model")
model.eval()

def predict(text: str) -> dict:
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=256)
    with torch.no_grad():
        outputs = model(**inputs)
    probs = torch.softmax(outputs.logits, dim=-1)
    pred = torch.argmax(probs, dim=-1).item()
    return {
        "label": pred,
        "confidence": round(probs[0][pred].item(), 4),
        "result": "敏感" if pred == 1 else "正常",
    }
```

$\operatorname{softmax}$ 把原始分数映射成概率分布，并满足两列概率之和为 $1$；$\operatorname{argmax}$ 取概率最大的类别。`probs[0][pred]` 就是模型对自己判断的置信度。

用法：

```python
print(predict("限时优惠加微信领取"))
# {'label': 1, 'confidence': 0.9731, 'result': '敏感'}

print(predict("2025年度开源项目汇总"))
# {'label': 0, 'confidence': 0.9856, 'result': '正常'}
```

`predict.py` 顺带做了批量推理逻辑，可以批量处理：

```bash
python predict.py --model ./best_model --input test.csv --output results.csv
```

---

## 处理数据

目前选择的数据集还算比较平均，如果你的数据比例不对，比如正常内容多于敏感内容很多，AI 发现 `无脑猜正常` 就能达到 $95\%$ 准确率，那它就偷懒真的往这个方向学。

有办法对抗这个问题：

### 加权损失函数

给少数类更大的损失权重，让 AI 更在意少数类的错误。

```python
from torch import nn

class WeightedTrainer(Trainer):
    def compute_loss(self, model, inputs, return_outputs=False, **kwargs):
        labels = inputs.pop("labels")
        outputs = model(**inputs)
        # 假设敏感样本 (1) 很少，那就给它 5 倍权重
        weight = torch.tensor([1.0, 5.0]).to(labels.device)
        loss_fn = nn.CrossEntropyLoss(weight=weight)
        loss = loss_fn(outputs.logits, labels)
        return (loss, outputs) if return_outputs else loss
```

把 `Trainer` 换成 `WeightedTrainer`，其他代码不变。权重比例根据实际样本比调整，比如正负比是 $10:1$，那权重设为 $\left[1.0, 10.0\right]$ 是一个起点。

### 过采样

在构建 Dataset 之前，对少数类做重复采样，使其数量接近多数类。简单粗暴，但是非常直接。

```python
from sklearn.utils import resample

# 假设敏感样本 (1) 很少
df_majority = df[df["label"] == 0]
df_minority = df[df["label"] == 1]
df_minority_upsampled = resample(df_minority, replace=True, n_samples=len(df_majority), random_state=42)
df = pd.concat([df_majority, df_minority_upsampled])
```


---

## 开始训练

:::success[完整训练代码 train.py]
```python line-numbers
"""
DistilBERT 文本分类训练脚本
用法: python train.py --data train.csv --output ./best_model
"""

import argparse

import numpy as np
import pandas as pd
import torch
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from sklearn.model_selection import train_test_split
from torch.utils.data import Dataset
from transformers import (
    DistilBertForSequenceClassification,
    DistilBertTokenizerFast,
    Trainer,
    TrainingArguments,
)


class TextDataset(Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels

    def __getitem__(self, idx):
        item = {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
        item["labels"] = torch.tensor(self.labels[idx])
        return item

    def __len__(self):
        return len(self.labels)


def compute_metrics(pred):
    labels = pred.label_ids
    preds = np.argmax(pred.predictions, axis=-1)
    precision, recall, f1, _ = precision_recall_fscore_support(
        labels, preds, average="binary"
    )
    acc = accuracy_score(labels, preds)
    return {"accuracy": acc, "f1": f1, "precision": precision, "recall": recall}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=str, default="train.csv")
    parser.add_argument("--output", type=str, default="./best_model")
    parser.add_argument(
        "--model_name", type=str, default="distilbert-base-multilingual-cased"
    )
    parser.add_argument("--epochs", type=int, default=3)
    parser.add_argument("--batch_size", type=int, default=16)
    parser.add_argument("--max_length", type=int, default=256)
    parser.add_argument("--test_size", type=float, default=0.2)
    args = parser.parse_args()

    # 加载数据
    df = pd.read_csv(args.data)
    print(
        f"数据集: {len(df)} 条, "
        f"正常: {(df['label']==0).sum()}, "
        f"敏感: {(df['label']==1).sum()}"
    )

    train_texts, val_texts, train_labels, val_labels = train_test_split(
        df["text"].tolist(),
        df["label"].tolist(),
        test_size=args.test_size,
        random_state=42,
        stratify=df["label"],
    )

    # 分词
    tokenizer = DistilBertTokenizerFast.from_pretrained(args.model_name)
    train_encodings = tokenizer(
        train_texts, truncation=True, padding=True, max_length=args.max_length
    )
    val_encodings = tokenizer(
        val_texts, truncation=True, padding=True, max_length=args.max_length
    )

    train_dataset = TextDataset(train_encodings, train_labels)
    val_dataset = TextDataset(val_encodings, val_labels)

    # 模型
    model = DistilBertForSequenceClassification.from_pretrained(
        args.model_name, num_labels=2
    )

    training_args = TrainingArguments(
        output_dir="./results",
        num_train_epochs=args.epochs,
        per_device_train_batch_size=args.batch_size,
        per_device_eval_batch_size=64,
        warmup_ratio=0.1,
        weight_decay=0.01,
        logging_dir="./logs",
        logging_steps=10,
        eval_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="f1",
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
        compute_metrics=compute_metrics,
    )

    trainer.train()

    # 保存
    trainer.save_model(args.output)
    tokenizer.save_pretrained(args.output)
    print(f"模型已保存到 {args.output}")

    # 最终评估
    results = trainer.evaluate()
    print(f"验证集结果: {results}")


if __name__ == "__main__":
    main()

```
:::

:::success[完整推理代码 predict.py]
```python line-numbers
"""
DistilBERT 文本分类推理脚本
用法:
  单条: python predict.py --model ./best_model --text "待检测文本"
  批量: python predict.py --model ./best_model --input test.csv --output results.csv
"""

import argparse

import pandas as pd
import torch
from transformers import DistilBertForSequenceClassification, DistilBertTokenizerFast


class Predictor:
    def __init__(self, model_dir: str):
        self.tokenizer = DistilBertTokenizerFast.from_pretrained(model_dir)
        self.model = DistilBertForSequenceClassification.from_pretrained(model_dir)
        self.model.eval()

    def predict(self, text: str) -> dict:
        inputs = self.tokenizer(
            text, return_tensors="pt", truncation=True, padding=True, max_length=256
        )
        with torch.no_grad():
            outputs = self.model(**inputs)
        probs = torch.softmax(outputs.logits, dim=-1)
        pred = torch.argmax(probs, dim=-1).item()
        return {
            "text": text,
            "label": pred,
            "confidence": round(probs[0][pred].item(), 4),
            "result": "敏感" if pred == 1 else "正常",
        }

    def predict_batch(self, texts: list[str], batch_size: int = 32) -> list[dict]:
        results = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            inputs = self.tokenizer(
                batch,
                return_tensors="pt",
                truncation=True,
                padding=True,
                max_length=256,
            )
            with torch.no_grad():
                outputs = self.model(**inputs)
            probs = torch.softmax(outputs.logits, dim=-1)
            preds = torch.argmax(probs, dim=-1)
            for j, (text, pred) in enumerate(zip(batch, preds)):
                p = pred.item()
                results.append(
                    {
                        "text": text,
                        "label": p,
                        "confidence": round(probs[j][p].item(), 4),
                        "result": "敏感" if p == 1 else "正常",
                    }
                )
        return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, default="./best_model")
    parser.add_argument("--text", type=str, help="单条文本预测")
    parser.add_argument("--input", type=str, help="批量预测的 CSV 文件")
    parser.add_argument("--output", type=str, default="results.csv")
    args = parser.parse_args()

    predictor = Predictor(args.model)

    if args.text:
        result = predictor.predict(args.text)
        print(f"文本: {result['text']}")
        print(f"结果: {result['result']} (置信度: {result['confidence']})")
    elif args.input:
        df = pd.read_csv(args.input)
        results = predictor.predict_batch(df["text"].tolist())
        out_df = pd.DataFrame(results)
        out_df.to_csv(args.output, index=False, encoding="utf-8-sig")
        print(f"结果已保存到 {args.output}, 共 {len(results)} 条")
    else:
        print("请指定 --text 或 --input 参数")


if __name__ == "__main__":
    main()

```
:::

现在，可以开始训练了！

你也可以从 [GitHub](https://github.com/ILoveScratch2/Content-Moderation) 上获取我的源代码。

使用 [Olivi-9/Chinese-Spam-Dataset](https://github.com/Olivi-9/Chinese-Spam-Dataset/) 先进行测试，其中有 $11799$ 条数据。

> 注：Chinese-Spam-Dataset 这个数据集在我测试的时候遇到了部分格式不太规范的问题，直接加载可能会报 ValueError 错误，如果出现这种情况需要修复数据集。
> 建议先检查一下 CSV 文件的格式，确保每行都有两列和逗号，并且没有缺失值。

```bash
git clone https://github.com/ILoveScratch2/Content-Moderation.git
cd Content-Moderation
pip install -r requirements.txt
python train.py --data train.csv
```

鉴于我家里~~没有矿~~没有办法长时间训练，所以我选择了使用云端 GPU 来训练模型。

在 NVIDIA Tesla T4 GPU 上，批大小为 $16$ 时，大约需要 $10$ 分钟（已经是批大小为 $16$ 时的极限了；其实根本就没有跑满 GPU，批大小再开大一点大概能压到 $5$ 分钟内，不过第一次没有经验，开小了）。训练结束后会在 `./best_model` 目录下保存模型权重和分词器。

```bash
Fri Apr 17 10:26:39 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.82.07              Driver Version: 580.82.07      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       Off |   00000000:00:04.0 Off |                    0 |
| N/A   71C    P0             65W /   70W |    3445MiB /  15360MiB |    100%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A            2429      C   python3                                3442MiB |
+-----------------------------------------------------------------------------------------+
```

```bash
数据集: 11799 条, 正常: 5676, 敏感: 6123
Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
tokenizer_config.json: 100% 49.0/49.0 [00:00<00:00, 181kB/s]
vocab.txt: 996kB [00:00, 6.14MB/s]
tokenizer.json: 1.96MB [00:00, 17.7MB/s]
config.json: 100% 466/466 [00:00<00:00, 2.03MB/s]
model.safetensors: 100% 542M/542M [00:06<00:00, 88.6MB/s]
Loading weights: 100% 100/100 [00:00<00:00, 1312.43it/s, Materializing param=distilbert.transformer.layer.5.sa_layer_norm.weight]
DistilBertForSequenceClassification LOAD REPORT from: distilbert-base-multilingual-cased
Key                     | Status     | 
------------------------+------------+-
vocab_transform.bias    | UNEXPECTED | 
vocab_layer_norm.weight | UNEXPECTED | 
vocab_layer_norm.bias   | UNEXPECTED | 
vocab_transform.weight  | UNEXPECTED | 
vocab_projector.bias    | UNEXPECTED | 
classifier.bias         | MISSING    | 
classifier.weight       | MISSING    | 
pre_classifier.bias     | MISSING    | 
pre_classifier.weight   | MISSING    | 

Notes:
- UNEXPECTED	:can be ignored when loading from different task/architecture; not ok if you expect identical arch.
- MISSING	:those params were newly initialized because missing from the checkpoint. Consider training on your downstream task.
warmup_ratio is deprecated and will be removed in v5.2. Use `warmup_steps` instead.
`logging_dir` is deprecated and will be removed in v5.2. Please set `TENSORBOARD_LOGGING_DIR` instead.
{'loss': '0.6914', 'grad_norm': '1.392', 'learning_rate': '2.542e-06', 'epoch': '0.01695'}
{'loss': '0.6772', 'grad_norm': '1.443', 'learning_rate': '5.367e-06', 'epoch': '0.0339'}
{'loss': '0.6633', 'grad_norm': '1.654', 'learning_rate': '8.192e-06', 'epoch': '0.05085'}
{'loss': '0.5963', 'grad_norm': '1.902', 'learning_rate': '1.102e-05', 'epoch': '0.0678'}
{'loss': '0.4902', 'grad_norm': '2.045', 'learning_rate': '1.384e-05', 'epoch': '0.08475'}
{'loss': '0.3553', 'grad_norm': '3.995', 'learning_rate': '1.667e-05', 'epoch': '0.1017'}
{'loss': '0.3332', 'grad_norm': '7.403', 'learning_rate': '1.949e-05', 'epoch': '0.1186'}
{'loss': '0.3154', 'grad_norm': '4.276', 'learning_rate': '2.232e-05', 'epoch': '0.1356'}
{'loss': '0.3399', 'grad_norm': '1.53', 'learning_rate': '2.514e-05', 'epoch': '0.1525'}
{'loss': '0.2683', 'grad_norm': '4.685', 'learning_rate': '2.797e-05', 'epoch': '0.1695'}
{'loss': '0.1969', 'grad_norm': '6.578', 'learning_rate': '3.079e-05', 'epoch': '0.1864'}
{'loss': '0.2654', 'grad_norm': '7.867', 'learning_rate': '3.362e-05', 'epoch': '0.2034'}
{'loss': '0.2625', 'grad_norm': '3.846', 'learning_rate': '3.644e-05', 'epoch': '0.2203'}
{'loss': '0.227', 'grad_norm': '5.243', 'learning_rate': '3.927e-05', 'epoch': '0.2373'}
{'loss': '0.1847', 'grad_norm': '4.576', 'learning_rate': '4.209e-05', 'epoch': '0.2542'}

--省略--

{'loss': '0.00919', 'grad_norm': '0.05978', 'learning_rate': '2.542e-06', 'epoch': '2.864'}
{'loss': '0.006814', 'grad_norm': '0.04127', 'learning_rate': '2.228e-06', 'epoch': '2.881'}
{'loss': '0.00192', 'grad_norm': '0.06398', 'learning_rate': '1.915e-06', 'epoch': '2.898'}
{'loss': '0.08475', 'grad_norm': '0.04405', 'learning_rate': '1.601e-06', 'epoch': '2.915'}
{'loss': '0.01414', 'grad_norm': '0.06212', 'learning_rate': '1.287e-06', 'epoch': '2.932'}
{'loss': '0.1301', 'grad_norm': '0.06911', 'learning_rate': '9.73e-07', 'epoch': '2.949'}
{'loss': '0.03935', 'grad_norm': '1.783', 'learning_rate': '6.591e-07', 'epoch': '2.966'}
{'loss': '0.04636', 'grad_norm': '3.594', 'learning_rate': '3.453e-07', 'epoch': '2.983'}
{'loss': '0.08538', 'grad_norm': '8.105', 'learning_rate': '3.139e-08', 'epoch': '3'}
{'eval_loss': '0.1591', 'eval_accuracy': '0.9602', 'eval_f1': '0.9615', 'eval_precision': '0.9654', 'eval_recall': '0.9576', 'eval_runtime': '18.5', 'eval_samples_per_second': '127.6', 'eval_steps_per_second': '2', 'epoch': '3'}                              
Writing model shards: 100% 1/1 [00:10<00:00, 10.88s/it]
There were missing keys in the checkpoint model loaded: ['distilbert.embeddings.LayerNorm.weight', 'distilbert.embeddings.LayerNorm.bias'].
There were unexpected keys in the checkpoint model loaded: ['distilbert.embeddings.LayerNorm.beta', 'distilbert.embeddings.LayerNorm.gamma'].
{'train_runtime': '766.9', 'train_samples_per_second': '36.92', 'train_steps_per_second': '2.308', 'train_loss': '0.135', 'epoch': '3'}
100% 1770/1770 [12:46<00:00,  2.31it/s]
Writing model shards: 100% 1/1 [00:09<00:00,  9.04s/it]
模型已保存到 ./best_model
100% 37/37 [00:17<00:00,  2.10it/s]
验证集结果: {'eval_loss': 0.1591474562883377, 'eval_accuracy': 0.9601694915254237, 'eval_f1': 0.9614754098360656, 'eval_precision': 0.9654320987654321, 'eval_recall': 0.9575510204081633, 'eval_runtime': 18.1345, 'eval_samples_per_second': 130.139, 'eval_steps_per_second': 2.04, 'epoch': 3.0}
```

模型训练完成，验证集准确率达到了 $96.02\%$，$F_1$ 达到了 $0.9615$，表现不错！

模型被自动保存到了 `./best_model` 目录下，加载时需要指定这个路径。

当前模型总大小约为 $519\,\text{MB}$，包含了 DistilBERT 的权重和分类头的权重。

然后测试一下成果：

```bash
python predict.py --model ./best_model --text "限时抢购！全网低价，品牌手机直降1000元，领券再减200，点击购买 http://example.com 联系客服微信：wxid_abc123 活动截止8月31日"

Loading weights: 100% 104/104 [00:00<00:00, 1074.86it/s, Materializing param=pre_classifier.weight]
文本: 限时抢购！全网低价，品牌手机直降1000元，领券再减200，点击购买 http://example.com 联系客服微信：wxid_abc123 活动截止8月31日
结果: 敏感 (置信度: 0.9996)
```


```bash
python predict.py --model ./best_model --text "减肥神药，月瘦20斤不反弹，纯天然成分，买三送一加赠疗程，支持货到付款，订购热线 400-123-4567"

Loading weights: 100% 104/104 [00:00<00:00, 1082.18it/s, Materializing param=pre_classifier.weight]
文本: 减肥神药，月瘦20斤不反弹，纯天然成分，买三送一加赠疗程，支持货到付款，订购热线 400-123-4567
结果: 敏感 (置信度: 0.9986)
```

```bash
!python predict.py --model ./best_model --text "【限时抢购】✅ 天然草本降压茶，3 盒一疗程，无效包退！🔥 今日特价：原价 598 元 → 现价仅需 198 元！📞 抢购热线：400-123-1234📱 添加营养师微信：1233211234567📍 联系地址：XX 省 XX 市高新区创业大厦 X 座 X 层👉 点击领取优惠券：http://example.com/go?id=1234"

Loading weights: 100% 104/104 [00:00<00:00, 985.45it/s, Materializing param=pre_classifier.weight]
文本: 【限时抢购】✅ 天然草本降压茶，3 盒一疗程，无效包退！🔥 今日特价：原价 598 元 → 现价仅需 198 元！📞 抢购热线：400-123-1234📱 添加营养师微信：1233211234567📍 联系地址：XX 省 XX 市高新区创业大厦 X 座 X 层👉 点击领取优惠券：http://example.com/go?id=1234
结果: 敏感 (置信度: 0.9994)
```

```bash
python predict.py --model ./best_model --text "2025年度开源项目汇总：1. TensorFlow 2.0 发布，带来更简洁的 API 和更高的性能；2. PyTorch 1.10 引入新的分布式训练功能；3. HuggingFace Transformers 4.0 支持更多预训练模型；4. FastAPI 成为最受欢迎的 Python Web 框架之一；5. Kubernetes 继续主导容器编排领域；6. Rust 在系统编程和 WebAssembly 领域持续增长；7. Go 语言在云原生开发中占据重要地位；8. React 18 发布，带来并发特性和性能提升；9. Vue.js 3.0 引入 Composition API；10. Angular 12 发布，改进性能和开发体验。"

Loading weights: 100% 104/104 [00:00<00:00, 2815.70it/s, Materializing param=pre_classifier.weight]
文本: 2025年度开源项目汇总：1. TensorFlow 2.0 发布，带来更简洁的 API 和更高的性能；2. PyTorch 1.10 引入新的分布式训练功能；3. HuggingFace Transformers 4.0 支持更多预训练模型；4. FastAPI 成为最受欢迎的 Python Web 框架之一；5. Kubernetes 继续主导容器编排领域；6. Rust 在系统编程和 WebAssembly 领域持续增长；7. Go 语言在云原生开发中占据重要地位；8. React 18 发布，带来并发特性和性能提升；9. Vue.js 3.0 引入 Composition API；10. Angular 12 发布，改进性能和开发体验。
结果: 正常 (置信度: 0.9957)
```

```bash
python predict.py --model ./best_model --text "clion webstorm goland早就都不用了，还是vscode香，pycharm也就是偶尔会用用，vscode就能满足日常了"

Loading weights: 100% 104/104 [00:00<00:00, 1208.59it/s, Materializing param=pre_classifier.weight]
文本: clion webstorm goland早就都不用了，还是vscode香，pycharm也就是偶尔会用用，vscode就能满足日常了
结果: 正常 (置信度: 0.9987)
```

```bash
python predict.py --model ./best_model --text "要辨别真假促销信息，提到“免费”、“限时”等词汇也别盲信。"

Loading weights: 100% 104/104 [00:00<00:00, 2976.59it/s, Materializing param=pre_classifier.weight]
文本: 要辨别真假促销信息，提到“免费”、“限时”等词汇也别盲信。
结果: 正常 (置信度: 0.9982)
```

```bash
python predict.py --model ./best_model --text "特别赞助鸣谢：感谢 CloudFlare 为本项目提供 CDN 支持"

Loading weights: 100% 104/104 [00:00<00:00, 931.91it/s, Materializing param=pre_classifier.weight]
文本: 特别赞助鸣谢：感谢 CloudFlare 为本项目提供 CDN 支持
结果: 正常 (置信度: 0.9982)
```

```bash
python predict.py --model ./best_model --text "如何识别“促销”、“免费领取”、“点击这里”和“推广内容”？以谷歌广告联盟为例，它的 HTML 代码中常常包含 class=adsbygoogle 这样的容器。有趣的是，很多社区论坛为了防止灌水，会禁止用户发送包含“http://” 或 “www” 的文字，但这导致很多人只是粘贴普通链接也会被删除。这种误判在广告拦截规则中被称为“假阳性（False Positive）”"

Loading weights: 100% 104/104 [00:00<00:00, 1176.39it/s, Materializing param=pre_classifier.weight]
文本: 如何识别“促销”、“免费领取”、“点击这里”和“推广内容”？以谷歌广告联盟为例，它的 HTML 代码中常常包含 class=adsbygoogle 这样的容器。有趣的是，很多社区论坛为了防止灌水，会禁止用户发送包含“http://” 或 “www” 的文字，但这导致很多人只是粘贴普通链接也会被删除。这种误判在广告拦截规则中被称为“假阳性（False Positive）”
结果: 正常 (置信度: 0.9986)
```

可见，目前的 AI 模型对广告类敏感内容的识别效果不错，能够正确判断广告文本为敏感，并且对正常文本的误判很少。不过这只是一个初步的模型，实际应用中还需要更多的数据来进一步提升。

所以，我又使用了 [Chinese-Offensive-Language-Dataset](https://github.com/royal12646/Chinese-offensive-language-detect/) 这个数据集中的 `AbuseSet` 和 `SexHarmSet` 来训练模型，增加了更多的敏感样本，提升了模型的泛化能力。

不过，这个数据集的格式和之前的不同。是三列的 CSV：
```
Keyword,Type,Sentence
关键词,Safe,正常内容
关键词,Harmful,敏感内容
```

所以我又写了一个转换脚本来把它转换成之前的两列格式：

:::success[数据转换代码 convert.py]
```python line-numbers
"""
合并 Chinese-Spam-Dataset 与 Chinese-offensive-language-detect：
- 第一个传入文件格式（COLD 格式）: Keyword,Type,Sentence
- 第二个传入文件格式（CSD 格式）: label,text
- 合并后输出统一格式的CSV
"""

import csv
import argparse
from pathlib import Path


def convert_first_csv(input_path):
    rows = []
    with open(input_path, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        fieldnames = [name.strip() for name in reader.fieldnames]
        for row in reader:
            kw = row.get('Keyword', '').strip()
            typ = row.get('Type', '').strip()
            sent = row.get('Sentence', '').strip()
            if typ.lower() == 'harmful':
                label = 1
            elif typ.lower() == 'safe':
                label = 0
            else:
                print(f"警告: 未知类型 '{typ}'，跳过该行: {row}", file=__import__('sys').stderr)
                continue
            
            rows.append({'label': label, 'text': sent})
    return rows


def read_second_csv(input_path):
    rows = []
    with open(input_path, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                label = int(row.get('label', '').strip())
            except ValueError:
                print(f"警告: 无法解析label值 '{row.get('label')}'，跳过该行", file=__import__('sys').stderr)
                continue
            text = row.get('text', '').strip()
            rows.append({'label': label, 'text': text})
    return rows


def write_merged_csv(output_path, rows):
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['label', 'text'])
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description='转换并合并两个CSV文件')
    parser.add_argument('first_csv', help='COLD CSV文件路径（Keyword,Type,Sentence）')
    parser.add_argument('second_csv', help='CSD CSV文件路径（label,text）')
    parser.add_argument('-o', '--output', default='merged_output.csv', help='输出文件路径（默认 merged_output.csv）')
    args = parser.parse_args()
    if not Path(args.first_csv).exists():
        print(f"错误: 文件不存在 - {args.first_csv}", file=__import__('sys').stderr)
        return 1
    if not Path(args.second_csv).exists():
        print(f"错误: 文件不存在 - {args.second_csv}", file=__import__('sys').stderr)
        return 1
    
    print(f"正在转换第一个文件: {args.first_csv}")
    rows1 = convert_first_csv(args.first_csv)
    print(f"已转换 {len(rows1)} 行")
    
    print(f"正在读取第二个文件: {args.second_csv}")
    rows2 = read_second_csv(args.second_csv)
    print(f"已读取 {len(rows2)} 行")
    
    all_rows = rows1 + rows2
    print(f"合并后总计 {len(all_rows)} 行")
    
    write_merged_csv(args.output, all_rows)
    print(f"结果已保存至: {args.output}")


if __name__ == '__main__':
    exit(main() or 0)

```
:::

转换后，使用新数据集重新训练模型，不过这次我略微调大了一些批大小；这次训练了 $27$ 分钟：

```bash
Sun Apr 19 07:10:38 2026       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.82.07              Driver Version: 580.82.07      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       Off |   00000000:00:04.0 Off |                    0 |
| N/A   77C    P0             63W /   70W |   12195MiB /  15360MiB |    100%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A            1080      C   python3                               12192MiB |
+-----------------------------------------------------------------------------------------+
```

```bash
python train.py --data merged_output.csv

数据集: 32848 条, 正常: 16140, 敏感: 16708
tokenizer_config.json: 100% 49.0/49.0 [00:00<00:00, 207kB/s]
Warning: You are sending unauthenticated requests to the HF Hub. Please set a HF_TOKEN to enable higher rate limits and faster downloads.
vocab.txt: 996kB [00:00, 5.13MB/s]
tokenizer.json: 1.96MB [00:00, 11.4MB/s]
config.json: 100% 466/466 [00:00<00:00, 1.94MB/s]
model.safetensors: 100% 542M/542M [00:05<00:00, 106MB/s] 
Loading weights: 100% 100/100 [00:00<00:00, 883.02it/s, Materializing param=distilbert.transformer.layer.5.sa_layer_norm.weight]
DistilBertForSequenceClassification LOAD REPORT from: distilbert-base-multilingual-cased
Key                     | Status     | 
------------------------+------------+-
vocab_transform.weight  | UNEXPECTED | 
vocab_layer_norm.weight | UNEXPECTED | 
vocab_projector.bias    | UNEXPECTED | 
vocab_transform.bias    | UNEXPECTED | 
vocab_layer_norm.bias   | UNEXPECTED | 
pre_classifier.bias     | MISSING    | 
classifier.bias         | MISSING    | 
pre_classifier.weight   | MISSING    | 
classifier.weight       | MISSING    | 

Notes:
- UNEXPECTED	:can be ignored when loading from different task/architecture; not ok if you expect identical arch.
- MISSING	:those params were newly initialized because missing from the checkpoint. Consider training on your downstream task.
warmup_ratio is deprecated and will be removed in v5.2. Use `warmup_steps` instead.
`logging_dir` is deprecated and will be removed in v5.2. Please set `TENSORBOARD_LOGGING_DIR` instead.
{'loss': '0.6903', 'grad_norm': '0.7476', 'learning_rate': '7.258e-06', 'epoch': '0.04854'}
{'loss': '0.6525', 'grad_norm': '0.9284', 'learning_rate': '1.532e-05', 'epoch': '0.09709'}
{'loss': '0.5376', 'grad_norm': '1.206', 'learning_rate': '2.339e-05', 'epoch': '0.1456'}
{'loss': '0.3244', 'grad_norm': '4.827', 'learning_rate': '3.145e-05', 'epoch': '0.1942'}
{'loss': '0.2588', 'grad_norm': '1.886', 'learning_rate': '3.952e-05', 'epoch': '0.2427'}
{'loss': '0.2792', 'grad_norm': '1.561', 'learning_rate': '4.758e-05', 'epoch': '0.2913'}
{'loss': '0.2178', 'grad_norm': '1.614', 'learning_rate': '4.937e-05', 'epoch': '0.3398'}
{'loss': '0.2012', 'grad_norm': '2.937', 'learning_rate': '4.847e-05', 'epoch': '0.3883'}
{'loss': '0.1752', 'grad_norm': '1.584', 'learning_rate': '4.757e-05', 'epoch': '0.4369'}
{'loss': '0.1803', 'grad_norm': '2.694', 'learning_rate': '4.667e-05', 'epoch': '0.4854'}
{'loss': '0.1382', 'grad_norm': '2.493', 'learning_rate': '4.577e-05', 'epoch': '0.534'}
{'loss': '0.1225', 'grad_norm': '3.001', 'learning_rate': '4.487e-05', 'epoch': '0.5825'}
{'loss': '0.1087', 'grad_norm': '1.577', 'learning_rate': '4.397e-05', 'epoch': '0.6311'}
{'loss': '0.1312', 'grad_norm': '2.736', 'learning_rate': '4.308e-05', 'epoch': '0.6796'}
{'loss': '0.1487', 'grad_norm': '1.708', 'learning_rate': '4.218e-05', 'epoch': '0.7282'}
{'loss': '0.1394', 'grad_norm': '1.889', 'learning_rate': '4.128e-05', 'epoch': '0.7767'}
{'loss': '0.126', 'grad_norm': '1.933', 'learning_rate': '4.038e-05', 'epoch': '0.8252'}
--省略--
{'loss': '0.03395', 'grad_norm': '1.018', 'learning_rate': '1.25e-05', 'epoch': '2.33'}
{'loss': '0.03417', 'grad_norm': '0.5612', 'learning_rate': '1.16e-05', 'epoch': '2.379'}
{'loss': '0.02612', 'grad_norm': '1.466', 'learning_rate': '1.07e-05', 'epoch': '2.427'}
{'loss': '0.02832', 'grad_norm': '0.3267', 'learning_rate': '9.802e-06', 'epoch': '2.476'}
{'loss': '0.02644', 'grad_norm': '1.558', 'learning_rate': '8.903e-06', 'epoch': '2.524'}
{'loss': '0.03933', 'grad_norm': '1.394', 'learning_rate': '8.004e-06', 'epoch': '2.573'}
{'loss': '0.02567', 'grad_norm': '1.221', 'learning_rate': '7.104e-06', 'epoch': '2.621'}
{'loss': '0.02192', 'grad_norm': '2.889', 'learning_rate': '6.205e-06', 'epoch': '2.67'}
{'loss': '0.03535', 'grad_norm': '1.82', 'learning_rate': '5.306e-06', 'epoch': '2.718'}
{'loss': '0.02716', 'grad_norm': '0.5141', 'learning_rate': '4.406e-06', 'epoch': '2.767'}
{'loss': '0.04632', 'grad_norm': '1.222', 'learning_rate': '3.507e-06', 'epoch': '2.816'}
{'loss': '0.01787', 'grad_norm': '2.083', 'learning_rate': '2.608e-06', 'epoch': '2.864'}
{'loss': '0.02531', 'grad_norm': '1.979', 'learning_rate': '1.709e-06', 'epoch': '2.913'}
{'loss': '0.04619', 'grad_norm': '1.59', 'learning_rate': '8.094e-07', 'epoch': '2.961'}
{'eval_loss': '0.1007', 'eval_accuracy': '0.9726', 'eval_f1': '0.973', 'eval_precision': '0.9751', 'eval_recall': '0.971', 'eval_runtime': '52.76', 'eval_samples_per_second': '124.5', 'eval_steps_per_second': '1.952', 'epoch': '3'}                                 
Writing model shards:   0% 0/1 [00:00<?, ?it/s]
Writing model shards: 100% 1/1 [00:04<00:00,  4.34s/it]
There were missing keys in the checkpoint model loaded: ['distilbert.embeddings.LayerNorm.weight', 'distilbert.embeddings.LayerNorm.bias'].
There were unexpected keys in the checkpoint model loaded: ['distilbert.embeddings.LayerNorm.beta', 'distilbert.embeddings.LayerNorm.gamma'].
{'train_runtime': '1862', 'train_samples_per_second': '42.34', 'train_steps_per_second': '0.332', 'train_loss': '0.1112', 'epoch': '3'}
100% 618/618 [31:02<00:00,  3.01s/it]
Writing model shards: 100% 1/1 [00:02<00:00,  2.34s/it]
模型已保存到 ./best_model
100% 103/103 [00:53<00:00,  1.93it/s]
验证集结果: {'eval_loss': 0.10065314918756485, 'eval_accuracy': 0.9726027397260274, 'eval_f1': 0.9730134932533733, 'eval_precision': 0.9750600961538461, 'eval_recall': 0.9709754637941352, 'eval_runtime': 53.7849, 'eval_samples_per_second': 122.153, 'eval_steps_per_second': 1.915, 'epoch': 3.0}
```
模型训练完成，现在，模型不只是能识别广告类敏感内容了，还能识别一些其他类型的敏感内容了！

这次的验证集准确率达到 $97.26\%$，$F_1$ 达到 $0.973$，效果也不错。

但是在这里我似乎不能真的写敏感内容来测试，所以这里不写测试结果了，不过你可以自己测试一下，看看模型的表现。

本文就先到这里啦，如果你有任何问题或者建议，欢迎在评论区留言！

:::info[AI 使用说明]{open}
本文在完稿后使用 ChatGPT 优化了一些口语表述。
:::