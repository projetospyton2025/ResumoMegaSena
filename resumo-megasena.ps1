# resumo-megasena.ps1
# Script de instalacao e configuracao da aplicacao Mega-Sena

# Definir o caminho do projeto
$projectPath = "I:\Meu Drive\LoteriasCaixaSites\Loterias-Resumo\ResumoMegaSena"
$venvPath = Join-Path $projectPath "venv"

# Criar diretorio do projeto se nao existir
if (-not (Test-Path $projectPath)) {
    New-Item -ItemType Directory -Force -Path $projectPath
}
Set-Location $projectPath

# Criar estrutura de diretorios
$directories = @(
    "templates",
    "static\css"
)

foreach ($dir in $directories) {
    $dirPath = Join-Path $projectPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Force -Path $dirPath
    }
}

# Conteudo dos arquivos
$files = @{
    "requirements.txt" = @"
Flask==2.0.1
Werkzeug==2.0.1
Jinja2==3.0.1
requests==2.31.0
"@

    "app.py" = @'
from flask import Flask, render_template
import requests
import json
from datetime import datetime

app = Flask(__name__)

def format_currency(value):
    if isinstance(value, str):
        value = float(value)
    return "{:,.2f}".format(value).replace(",", "X").replace(".", ",").replace("X", ".")

@app.route('/')
def index():
    try:
        # Fazer requisição para a API
        response = requests.get('https://loteriascaixa-api.herokuapp.com/api/megasena/latest')
        data = response.json()

        # Processar os dados da API
        premiacoes = {premio['descricao']: premio for premio in data['premiacoes']}
        
        sorteio = {
            'numero': data['concurso'],
            'data': data['data'],
            'numeros': [int(num) for num in data['dezenas']],
            'numeros_ordem_sorteio': [int(num) for num in data['dezenasOrdemSorteio']],
            'acumulou': data['acumulou'],
            'local_sorteio': data['local'],
            'ganhadores': {
                'sena': premiacoes['6 acertos']['ganhadores'],
                'quina': premiacoes['5 acertos']['ganhadores'],
                'quadra': premiacoes['4 acertos']['ganhadores']
            },
            'premios': {
                'sena': premiacoes['6 acertos']['valorPremio'],
                'quina': premiacoes['5 acertos']['valorPremio'],
                'quadra': premiacoes['4 acertos']['valorPremio']
            },
            'proximo_concurso': {
                'data': data['dataProximoConcurso'],
                'numero': data['proximoConcurso'],
                'estimativa_premio': data['valorEstimadoProximoConcurso']
            }
        }
    return render_template('index.html', sorteio=sorteio)

if __name__ == '__main__':
    app.run(debug=True)
'@

    "templates\index.html" = @'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resultados Mega-Sena</title>
    <script src="https://kit.fontawesome.com/afb02bf9ac.js" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Mega-Sena</h1>
            <h2>Concurso {{ sorteio.numero }} - {{ sorteio.data }}</h2>
        </div>

        <div class="cards-container">
            <!-- Card Resultado -->
            <div class="card">
                <h3>Resultado</h3>
                <div class="numeros">
                    {% for numero in sorteio.numeros %}
                    <div class="numero">{{ "%02d"|format(numero) }}</div>
                    {% endfor %}
                </div>
                <p class="local">Sorteio realizado em {{ sorteio.local_sorteio }}</p>
            </div>

            <!-- Card Premiação -->
            <div class="card">
                <h3>Premiação</h3>
                <div class="prize-info">
                    <p class="acumulou-text">{{ "ACUMULOU!" if sorteio.acumulou else "Premiado!" }}</p>
                    <p><i class="fas fa-trophy"></i> Sena (6): {{ sorteio.ganhadores.sena }} - R$ {{ "%.2f"|format(sorteio.premios.sena) }}</p>
                    <p><i class="fas fa-star"></i> Quina (5): {{ sorteio.ganhadores.quina }} - R$ {{ "%.2f"|format(sorteio.premios.quina) }}</p>
                    <p><i class="fas fa-check-circle"></i> Quadra (4): {{ sorteio.ganhadores.quadra }} - R$ {{ "%.2f"|format(sorteio.premios.quadra) }}</p>
                </div>
            </div>

            <!-- Card Próximo Concurso -->
            <div class="card">
                <h3>Próximo Concurso</h3>
                <div class="proximo-concurso">
                    <p><i class="fas fa-calendar-alt"></i> Concurso: {{ sorteio.proximo_concurso.numero }}</p>
                    <p><i class="fas fa-clock"></i> Data: {{ sorteio.proximo_concurso.data }}</p>
                    <p><i class="fas fa-money-bill-wave"></i> Prêmio Estimado:</p>
                    <p class="valor-estimado">R$ {{ "%.2f"|format(sorteio.proximo_concurso.estimativa_premio) }}</p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
'@

    "static\css\style.css" = @'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: Arial, sans-serif;
}

body {
    background-color: #f0f0f0;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.header {
    text-align: center;
    margin-bottom: 30px;
    color: #1b5e20;
}

.cards-container {
    display: flex;
    justify-content: space-between;
    gap: 20px;
    flex-wrap: wrap;
}

.card {
    background: white;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    flex: 1;
    min-width: 300px;
    transition: transform 0.2s;
}

.card:hover {
    transform: translateY(-5px);
}

.numeros {
    display: flex;
    justify-content: center;
    gap: 10px;
    margin: 20px 0;
}

.numero {
    width: 40px;
    height: 40px;
    background: #1b5e20;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
}

.prize-info p {
    margin: 10px 0;
}

.prize-info i {
    margin-right: 10px;
    color: #1b5e20;
}

.acumulou-text {
    font-size: 1.2em;
    font-weight: bold;
    color: #1b5e20;
    text-align: center;
    margin: 10px 0;
}

.proximo-concurso p {
    margin: 10px 0;
}

.valor-estimado {
    font-size: 1.5em;
    font-weight: bold;
    color: #1b5e20;
    text-align: center;
    margin-top: 10px;
}

.local {
    text-align: center;
    color: #666;
    margin-top: 10px;
}
'@
}

# Criar arquivos com seus conteudos
foreach ($file in $files.Keys) {
    $content = $files[$file]
    $filePath = Join-Path $projectPath $file
    Set-Content -Path $filePath -Value $content -Force -Encoding UTF8
}

# Criar e configurar ambiente virtual
python -m venv $venvPath

# Ativar ambiente virtual e instalar dependencias
& "$venvPath\Scripts\Activate.ps1"
pip install -r requirements.txt

Write-Host "Instalacao concluida! Para iniciar a aplicacao:"
Write-Host "1. Navegue ate $projectPath"
Write-Host "2. Ative o ambiente virtual: .\venv\Scripts\Activate.ps1"
Write-Host "3. Execute a aplicacao: python app.py"
Write-Host "4. Acesse http://localhost:5000 no navegador"