# 🚀 Gravidade Zero

> Jogo de plataforma 2D com desafios matemáticos ambientado no espaço sideral.

---

## 📋 Descrição

Gravidade Zero é um jogo 2D desenvolvido em Godot Engine 4 no qual o jogador controla um astronauta preso numa estação espacial avariada. Para escapar, é preciso explorar os setores da estação, coletar recursos, administrar o oxigênio disponível e resolver equações matemáticas que desbloqueiam as passagens.

**Gênero:** Plataforma 2D com puzzles matemáticos  
**Equipe:** Cauê Pereira, Maicon Mendes e Matheus Correia de Oliveira  
**Disciplina:** PAC — Projeto de Aplicação Computacional  
**Versão:** 1.0

---

## 🖥️ Requisitos

| Item | Versão mínima |
|------|--------------|
| Sistema operacional | Windows 10 64-bit |
| Godot Engine | **4.1** ou superior (testado no 4.6.1 stable) |
| Placa de vídeo | Compatível com Vulkan ou OpenGL 3.3 |
| RAM | 2 GB |
| Espaço em disco | ~50 MB |

> **Godot Engine** pode ser baixado gratuitamente em: https://godotengine.org/download

---

## 📥 Como baixar o projeto

### Opção 1 — Clonar via Git
```bash
git clone https://github.com/cauepereira/gravidade-zero.git
```

### Opção 2 — Baixar ZIP
1. Acesse o repositório no GitHub
2. Clique no botão verde **Code**
3. Selecione **Download ZIP**
4. Extraia a pasta em qualquer local do seu computador

---

## ⚙️ Como configurar o ambiente

1. Instale o **Godot Engine 4** (link nos requisitos acima)
2. **Não é necessário instalar nenhuma dependência adicional** — o projeto roda direto na engine
3. Abra o Godot Engine
4. Na tela inicial do Godot clique em **Import**
5. Navegue até a pasta do projeto e selecione o arquivo **`project.godot`**
6. Clique em **Import & Edit**

---

## ▶️ Como executar o jogo

### Pelo editor Godot
1. Com o projeto aberto no Godot, pressione **F5** ou clique no botão ▶ (Play) no canto superior direito
2. O jogo iniciará em uma janela de **1280 × 720**

### Pela cena principal
1. No painel FileSystem (inferior esquerdo), dê duplo clique em **`main.tscn`**
2. Pressione **F6** para rodar apenas essa cena

---

## 🎮 Como jogar

### Menu inicial
| Tecla | Ação |
|-------|------|
| `W` / `S` ou `↑` / `↓` | Navegar entre as opções |
| `Enter` ou `Espaço` | Confirmar seleção |
| `ESC` | Sair do jogo |

### Controles em jogo
| Tecla | Ação |
|-------|------|
| `W A S D` ou `↑ ← ↓ →` | Mover o astronauta |
| `Shift` (segurar) | Correr (consome energia do traje) |
| `E` | Interagir com terminais, gerador e saída |
| `1` / `2` / `3` | Responder equações nos terminais |
| `P` ou `ESC` | Pausar o jogo |
| `M` (na pausa ou fim de jogo) | Voltar ao menu principal |
| `R` ou `Enter` (fim de jogo) | Reiniciar |

---

## 🎯 Objetivo e regras

### Objetivo
Escapar da estação espacial seguindo um fluxo de 8 etapas:

```
1. Coletar o cartão azul de acesso
2. Usar o Terminal A para abrir a Porta A (resolver equação)
3. Coletar as 3 baterias de energia espalhadas pelo setor
4. Usar o Gerador para restaurar a energia da estação
5. Usar o Terminal B para desligar o laser (resolver equação)
6. Coletar o chip de código roxo
7. Usar o Terminal C para liberar a saída (resolver equação)
8. Entrar na saída e pressionar E para escapar
```

### Oxigênio
- O O2 diminui continuamente durante toda a partida
- Chegar a **zero de O2 = derrota**
- Cilindros de oxigênio verdes espalhados pelo mapa recarregam **+35 O2**
- Zonas de **radiação** (área vermelha com ⚠) drenam o O2 muito rapidamente — evite-as
- O O2 fica **pausado** enquanto um terminal está aberto

### Equações matemáticas
Cada terminal apresenta uma equação de álgebra com 3 opções de resposta:

| Terminal | Equação | Resposta correta |
|----------|---------|-----------------|
| Terminal A | x + 2 = 5 | x = 3 → opção **3** |
| Terminal B | 3x = 12 | x = 4 → opção **1** |
| Terminal C | 2x + 4 = 10 | x = 3 → opção **2** |

> Resposta errada = perde **8 de O2** e **5 pontos**. Não há limite de tentativas.

### Pontuação
| Ação | Pontos |
|------|--------|
| Coletar cartão | +20 |
| Coletar bateria | +15 |
| Coletar cilindro O2 | +10 |
| Resolver Terminal A | +50 |
| Ligar gerador | +60 |
| Resolver Terminal B | +70 |
| Coletar código | +30 |
| Resolver Terminal C | +80 |
| Escapar pela saída | +100 |
| Resposta errada | −5 |

### Condições de vitória e derrota
- **Vitória:** entrar na saída verde com `E` após resolver todos os terminais
- **Derrota:** oxigênio chegar a zero em qualquer momento

---

## 🗺️ Mapa da estação

```
[SALA INICIAL] → [SETOR DE ENERGIA] → [SETOR DE SEGURANÇA] → [CÓDIGO/SAÍDA]
   Cartão            Baterias               Laser                  Chip
   Terminal A        Gerador             Terminal B             Terminal C
   Cilindro O2       Cilindro O2                                  Saída
```

As divisórias entre setores são **paredes sólidas** que só abrem após resolver o desafio correspondente — não é possível ver nem passar para o próximo setor sem completar o puzzle.

---

## ⚠️ Limitações conhecidas da versão atual

- Os sons do jogo são **gerados sinteticamente por código** (sem arquivos de áudio externos). Em alguns computadores o som pode não funcionar dependendo da configuração de áudio do Godot.
- O jogo possui apenas **1 fase** (vertical slice).
- Não há sistema de **save** — ao fechar o jogo o progresso é perdido.
- Não há suporte a **controle de gamepad** — apenas teclado.
- A resolução é fixa em **1280 × 720** (sem opção de tela cheia nas configurações).
- As equações matemáticas são **fixas** (não mudam entre partidas), mas as posições dos itens coletáveis são **aleatórias** a cada partida.

---

## 📄 GDD (Game Design Document)

O GDD completo do projeto está disponível no arquivo **`LEIA-ME.txt`** na raiz deste repositório, contendo:
- Proposta e gênero do jogo
- Público-alvo
- Mecânicas e objetivos
- Fluxo da primeira partida
- Identidade visual
- Ficha técnica completa

---

## 🛠️ Ficha técnica

| Campo | Informação |
|-------|-----------|
| Nome | Gravidade Zero |
| Engine | Godot Engine 4.6.1 stable |
| Linguagem | GDScript |
| Plataforma | Windows (PC) |
| Resolução | 1280 × 720 |
| Controles | Teclado |
| Gênero | Plataforma 2D / Puzzle matemático |
| Classificação | Livre |

---

## 👥 Créditos

| Função | Nome |
|--------|------|
| Desenvolvimento | Cauê Pereira |
| Desenvolvimento | Maicon Mendes |
| Desenvolvimento | Matheus Correia de Oliveira |
| Engine | Godot Engine (MIT License) — godotengine.org |

---

*Projeto desenvolvido para a disciplina de PAC — 2025*
