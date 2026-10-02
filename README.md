# MouseSwitch

Ajusta automaticamente a velocidade do ponteiro no **Windows 11** conforme o dispositivo em uso: **mouse** ou **trackpad**.

Mexeu no mouse, a velocidade vai para 12. Encostou no trackpad, vai para 20. A troca acontece na hora, sem clicar em nada. Um ícone na bandeja do sistema mostra o modo atual e permite controle manual.

## Funcionalidades

- **Detecção automática** do dispositivo que está gerando a entrada, via Raw Input API do Windows.
- **Ícone na bandeja** com o modo atual:
  - 🔵 azul `12` = mouse · 🟢 verde `20` = trackpad
  - **círculo** = modo automático · **quadrado** = modo manual
- **Clique esquerdo** no ícone alterna o modo manualmente e pausa o automático.
- **Menu do clique direito**: Automático, Mouse, Trackpad, Ver último dispositivo, Sair.
- **Diagnóstico**: o item "Ver último dispositivo" mostra o nome do dispositivo que clicou no menu e como ele foi classificado.
- A configuração é **persistente**: grava no registro do Windows, como o Painel de Controle faz.
- **Instância única**: avisa se já houver uma cópia rodando.
- Sem dependências. É só PowerShell (nativo do Windows) com um trecho em C# compilado em tempo de execução.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `MouseSwitch.ps1` | Script principal com o ícone na bandeja, a detecção e a troca de velocidade. |
| `MouseSwitch.vbs` | Launcher que abre o script sem mostrar a janela do console. |

## Instalação

1. Baixe `MouseSwitch.ps1` e `MouseSwitch.vbs` e coloque os dois **na mesma pasta** (ex.: `C:\Tools\MouseSwitch`).
2. Dê dois cliques em `MouseSwitch.vbs`.
3. *(Opcional)* Para deixar o ícone sempre visível, arraste-o da seta `^` para a barra de tarefas, ou ative em **Configurações > Personalização > Barra de tarefas > Outros ícones da bandeja**.
4. *(Opcional)* Para iniciar com o Windows, pressione `Win + R`, digite `shell:startup` e crie ali um **atalho** para o `MouseSwitch.vbs`.

## Configuração

As opções ficam no topo do `MouseSwitch.ps1`:

```powershell
$MouseSpeed    = 12           # velocidade no mouse (1-20)
$TrackpadSpeed = 20           # velocidade no trackpad (1-20)
$MouseNameMatch = 'VID_|VID&' # regex: nomes de dispositivo que contam como MOUSE
```

A escala de 1 a 20 é a mesma do controle "Velocidade do ponteiro" do Windows.

## Como funciona

O script cria uma janela oculta e se registra na **Raw Input API** (`RegisterRawInputDevices`) para dois tipos de entrada:

- **Mouse genérico** (Usage Page `0x01`, Usage `0x02`)
- **Touchpad de precisão** (Usage Page `0x0D`, Usage `0x05`)

Cada evento `WM_INPUT` traz o *handle* do dispositivo de origem. O nome do dispositivo é obtido com `GetRawInputDeviceInfo` e classificado assim:

| Situação | Classificação |
|---|---|
| Evento HID do touchpad de precisão | Trackpad |
| Movimento sem dispositivo associado (sintetizado pelo touchpad de precisão) | Trackpad |
| Nome casa com `$MouseNameMatch` (`VID_` = USB, inclusive receptores sem fio · `VID&` = Bluetooth) | Mouse |
| Qualquer outro (ex.: touchpad interno I2C, `HID#VEN_...`) | Trackpad |

Quando o tipo muda, a velocidade é aplicada com `SystemParametersInfo(SPI_SETMOUSESPEED)`. A chamada só acontece na mudança de tipo, não a cada movimento.

## Solução de problemas

- **Classificação errada**: abra o menu e clique em **Ver último dispositivo**, uma vez usando o mouse e outra usando o trackpad. Compare os nomes e ajuste `$MouseNameMatch`. Para casar só com o seu receptor, use o identificador específico dele, ex.: `'VID_046D&PID_C52B'`.
- **Trackpad ainda lento no 20**: touchpads de precisão têm um controle de velocidade próprio em **Configurações > Bluetooth e dispositivos > Touchpad**, que se soma a esse.
- **"O MouseSwitch já está rodando"**: feche a instância anterior pelo menu (**Sair**) antes de abrir de novo.
- **Script bloqueado**: o launcher já usa `-ExecutionPolicy Bypass`. Se o arquivo veio da internet, clique com o botão direito nele, vá em **Propriedades** e marque **Desbloquear**.

## Requisitos

- Windows 10 ou 11
- Windows PowerShell 5.1 (já vem instalado)
