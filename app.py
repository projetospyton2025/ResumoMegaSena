# app.py
from flask import Flask, render_template
import requests
import json
from datetime import datetime
import locale
import os

app = Flask(__name__)

# Configurar localização para português brasileiro
locale.setlocale(locale.LC_ALL, 'pt_BR.UTF-8')

def format_currency(value):
    try:
        # Converter para float
        if isinstance(value, str):
            value = float(value.replace(',', '.'))
        else:
            value = float(value)
            
        # Formatar primeiro com ponto para milhares e ponto para decimal
        formatted = '{:,.2f}'.format(value)
        
        # Substituir para o padrão brasileiro:
        # 1. Primeiro troca a vírgula por um marcador temporário
        # 2. Depois troca o ponto por vírgula
        # 3. Por fim, troca o marcador temporário por ponto
        formatted = formatted.replace(',', '|').replace('.', ',').replace('|', '.')
        
        return formatted
    except:
        return '0,00'

def get_concurso(numero=None):
    try:
        if numero:
            url = f'https://loteriascaixa-api.herokuapp.com/api/megasena/{numero}'
        else:
            url = 'https://loteriascaixa-api.herokuapp.com/api/megasena/latest'
        
        response = requests.get(url)
        data = response.json()
        
        premiacoes = {premio['descricao']: premio for premio in data['premiacoes']}
        
        return {
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
                'sena': float(premiacoes['6 acertos']['valorPremio']),
                'quina': float(premiacoes['5 acertos']['valorPremio']),
                'quadra': float(premiacoes['4 acertos']['valorPremio'])
            },
            'proximo_concurso': {
                'data': data['dataProximoConcurso'],
                'numero': data['proximoConcurso'],
                'estimativa_premio': float(data['valorEstimadoProximoConcurso'])
            }
        }
    except Exception as e:
        print(f"Erro ao buscar concurso {numero}: {str(e)}")
        return None

@app.route('/')
def index():
    try:
        # Buscar o último concurso primeiro
        ultimo_concurso = get_concurso()
        if not ultimo_concurso:
            raise Exception("Não foi possível obter o último concurso")
            
        # Buscar os 5 concursos anteriores
        numero_atual = ultimo_concurso['numero']
        concursos = [ultimo_concurso]
        
        for i in range(1, 6):
            concurso = get_concurso(numero_atual - i)
            if concurso:
                concursos.append(concurso)
                
        return render_template('index.html', concursos=concursos, format_currency=format_currency)
        
    except Exception as e:
        return render_template('error.html', error="Erro: " + str(e))


"""
if __name__ == '__main__':
    app.run(debug=True)

"""


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)