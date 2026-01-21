VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cApiClient"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'*******************************************************************************
' Classe: cApiClient
' Propósito: Encapsular toda comunicação com a API REST
' PrincÃ­pios SOLID aplicados:
'   - Single Responsibility: Apenas gerencia comunicação HTTP/API
'   - Open/Closed: ExtensÃ­vel via métodos, fechado para modificação
'   - Dependency Inversion: Usa interfaces (XMLHTTP) ao invés de implementaçÃµes
'*******************************************************************************

Option Explicit

' Constantes privadas
Private Const BASE_URL As String = "https://nsgyn.com.br/api/"
Private Const CONTENT_TYPE_JSON As String = "application/json"
Private Const HEADER_ACCEPT As String = "application/json"

' Variáveis privadas de instÃ¢ncia
Private m_Token As String
Private m_BaseUrl As String
Private m_LastError As String
Private m_LastStatusCode As Long

'*******************************************************************************
' Propriedades PÃºblicas
'*******************************************************************************

Public Property Get Token() As String
    Token = m_Token
End Property

Public Property Let Token(ByVal Value As String)
    m_Token = Value
End Property

Public Property Get BaseUrl() As String
    If Len(m_BaseUrl) = 0 Then
        BaseUrl = BASE_URL
    Else
        BaseUrl = m_BaseUrl
    End If
End Property

Public Property Let BaseUrl(ByVal Value As String)
    ' Garante que a URL termina com "/"
    If Right(Value, 1) <> "/" Then
        m_BaseUrl = Value & "/"
    Else
        m_BaseUrl = Value
    End If
End Property

Public Property Get LastError() As String
    LastError = m_LastError
End Property

Public Property Get LastStatusCode() As Long
    LastStatusCode = m_LastStatusCode
End Property

'*******************************************************************************
' Métodos PÃºblicos - Autenticação
'*******************************************************************************

Public Function Login(ByVal email As String, ByVal password As String) As Boolean
    On Error GoTo ErrorHandler
    
    Dim oHttp As Object
    Dim jsonBody As String
    Dim response As Object
    
    ' Limpa erro anterior
    m_LastError = ""
    m_LastStatusCode = 0
    
    ' Prepara requisição
    Set oHttp = CreateObject("MSXML2.ServerXMLHTTP")
    jsonBody = BuildJsonLogin(email, password)
    
    ' Executa requisição
    oHttp.Open "POST", Me.BaseUrl & "login", False
    ConfigureJsonHeaders oHttp, False
    oHttp.send jsonBody
    
    ' Processa resposta
    m_LastStatusCode = oHttp.Status
    
    If oHttp.Status = 200 Or oHttp.Status = 201 Then
        Set response = JSON.parse(oHttp.responseText)
        m_Token = response.Item("token")
        Login = True
    Else
        m_LastError = "Falha no login. Status: " & oHttp.Status
        Login = False
    End If
    
    Set oHttp = Nothing
    Exit Function
    
ErrorHandler:
    m_LastError = "Erro no login: " & Err.Description
    Login = False
End Function

'*******************************************************************************
' Métodos PÃºblicos - Lojas
'*******************************************************************************

Public Function GetLojas() As Collection
    On Error GoTo ErrorHandler
    
    Dim oHttp As Object
    Dim response As Object
    Dim loja As Object
    Dim colLojas As New Collection
    
    ' Validação
    If Not IsAuthenticated() Then
        m_LastError = "Usuário não autenticado"
        Set GetLojas = Nothing
        Exit Function
    End If
    
    ' Limpa erro anterior
    m_LastError = ""
    m_LastStatusCode = 0
    
    ' Executa requisição
    Set oHttp = CreateObject("MSXML2.ServerXMLHTTP")
    oHttp.Open "GET", Me.BaseUrl & "lojas", False
    ConfigureJsonHeaders oHttp, True
    oHttp.send
    
    ' Processa resposta
    m_LastStatusCode = oHttp.Status
    
    If oHttp.Status = 200 Then
        Set response = JSON.parse(oHttp.responseText)
        For Each loja In response
            colLojas.Add loja
        Next
        Set GetLojas = colLojas
    Else
        m_LastError = "Erro ao buscar lojas. Status: " & oHttp.Status
        Set GetLojas = Nothing
    End If
    
    Set oHttp = Nothing
    Exit Function
    
ErrorHandler:
    m_LastError = "Erro ao buscar lojas: " & Err.Description
    Set GetLojas = Nothing
End Function

'*******************************************************************************
' Métodos PÃºblicos - Impressoras
'*******************************************************************************

Public Function CadastrarImpressora(ByVal identificador As String, _
                                    ByVal lojaId As Long, _
                                    ByVal modeloId As Long) As String
    On Error GoTo ErrorHandler
    
    Dim oHttp As Object
    Dim jsonBody As String
    Dim response As Object
    
    ' Validação
    If Not IsAuthenticated() Then
        CadastrarImpressora = "Erro: Usuário não autenticado"
        Exit Function
    End If
    
    ' Limpa erro anterior
    m_LastError = ""
    m_LastStatusCode = 0
    
    ' Prepara requisição
    Set oHttp = CreateObject("MSXML2.ServerXMLHTTP")
    jsonBody = BuildJsonImpressora(identificador, lojaId, modeloId)
    
    ' Executa requisição
    oHttp.Open "POST", Me.BaseUrl & "impressoras", False
    ConfigureJsonHeaders oHttp, True
    oHttp.send jsonBody
    
    ' Processa resposta
    m_LastStatusCode = oHttp.Status
    Set response = JSON.parse(oHttp.responseText)
    
    Select Case oHttp.Status
        Case 200, 201
            CadastrarImpressora = "Sucesso: " & response.Item("message")
        Case 409
            CadastrarImpressora = "Erro: Impressora já existe"
        Case 500
            CadastrarImpressora = "Erro: " & response.Item("message")
        Case Else
            CadastrarImpressora = "Erro desconhecido: " & oHttp.Status
    End Select
    
    Set oHttp = Nothing
    Exit Function
    
ErrorHandler:
    m_LastError = "Erro ao cadastrar impressora: " & Err.Description
    CadastrarImpressora = m_LastError
End Function

Public Function CadastrarImpressoraPorLoja(ByVal codigoLoja As String, _
                                           ByVal identificador As String, _
                                           ByVal modeloId As Long) As String
    On Error GoTo ErrorHandler
    
    Dim oHttp As Object
    Dim jsonBody As String
    Dim response As Object
    Dim endpoint As String
    
    ' Validação
    If Not IsAuthenticated() Then
        CadastrarImpressoraPorLoja = "Erro: Usuário não autenticado"
        Exit Function
    End If
    
    If Len(codigoLoja) = 0 Then
        CadastrarImpressoraPorLoja = "Erro: Código da loja é obrigatório"
        Exit Function
    End If
    
    ' Limpa erro anterior
    m_LastError = ""
    m_LastStatusCode = 0
    
    ' Prepara requisição
    Set oHttp = CreateObject("MSXML2.ServerXMLHTTP")
    jsonBody = BuildJsonImpressoraPorLoja(identificador, modeloId)
    endpoint = "lojas/" & codigoLoja & "/impressoras"
    
    ' Executa requisição
    oHttp.Open "POST", Me.BaseUrl & endpoint, False
    ConfigureJsonHeaders oHttp, True
    oHttp.send jsonBody
    
    ' Processa resposta
    m_LastStatusCode = oHttp.Status
    Set response = JSON.parse(oHttp.responseText)
    
    Select Case oHttp.Status
        Case 200, 201
            CadastrarImpressoraPorLoja = "Sucesso: " & response.Item("message")
        Case 404
            CadastrarImpressoraPorLoja = "Erro: Loja não encontrada"
        Case 409
            CadastrarImpressoraPorLoja = "Erro: Impressora já existe nesta loja"
        Case 422
            CadastrarImpressoraPorLoja = "Erro: Dados inválidos - " & response.Item("message")
        Case 500
            CadastrarImpressoraPorLoja = "Erro: " & response.Item("message")
        Case Else
            CadastrarImpressoraPorLoja = "Erro desconhecido: " & oHttp.Status
    End Select
    
    Set oHttp = Nothing
    Exit Function
    
ErrorHandler:
    m_LastError = "Erro ao cadastrar impressora por loja: " & Err.Description
    CadastrarImpressoraPorLoja = m_LastError
End Function

Public Function AtualizarContador(ByVal identificador As String, _
                                  ByVal contador As Long, _
                                  Optional ByRef mediaConsumo As String) As Boolean
    On Error GoTo ErrorHandler
    
    Dim oHttp As Object
    Dim jsonBody As String
    Dim response As Object
    
    ' Validação
    If Not IsAuthenticated() Then
        m_LastError = "Usuário não autenticado"
        AtualizarContador = False
        Exit Function
    End If
    
    ' Limpa erro anterior
    m_LastError = ""
    m_LastStatusCode = 0
    mediaConsumo = ""
    
    ' Prepara requisição
    Set oHttp = CreateObject("MSXML2.ServerXMLHTTP")
    jsonBody = BuildJsonContador(identificador, contador)
    
    ' Executa requisição
    oHttp.Open "POST", Me.BaseUrl & "impressoras/contador", False
    ConfigureJsonHeaders oHttp, True
    oHttp.send jsonBody
    
    ' Processa resposta
    m_LastStatusCode = oHttp.Status
    
    Select Case oHttp.Status
        Case 200, 201
            Set response = JSON.parse(oHttp.responseText)
            'mediaConsumo = CStr(response.Item("data").Item("media_consumo"))
            m_LastError = response.Item("message")
            AtualizarContador = True
            
        Case 404
            ' Impressora não existe - poderia cadastrar automaticamente
            m_LastError = "Impressora não encontrada"
            AtualizarContador = False
            
        Case 500
            Set response = JSON.parse(oHttp.responseText)
            m_LastError = response.Item("message")
            AtualizarContador = False
            
        Case Else
            m_LastError = "Erro desconhecido: " & oHttp.Status
            AtualizarContador = False
    End Select
    
    Set oHttp = Nothing
    Exit Function
    
ErrorHandler:
    m_LastError = "Erro ao atualizar contador: " & Err.Description
    AtualizarContador = False
End Function

'*******************************************************************************
' Métodos Privados - Helpers
'*******************************************************************************

Private Function IsAuthenticated() As Boolean
    IsAuthenticated = (Len(m_Token) > 0)
End Function

Private Sub ConfigureJsonHeaders(ByRef oHttp As Object, ByVal includeAuth As Boolean)
    oHttp.setRequestHeader "Content-Type", CONTENT_TYPE_JSON
    oHttp.setRequestHeader "Accept", HEADER_ACCEPT
    
    If includeAuth And IsAuthenticated() Then
        oHttp.setRequestHeader "Authorization", "Bearer " & m_Token
    End If
End Sub

Private Function BuildJsonLogin(ByVal email As String, ByVal password As String) As String
    BuildJsonLogin = "{""email"": """ & email & """, ""password"": """ & password & """}"
End Function

Private Function BuildJsonImpressora(ByVal identificador As String, _
                                     ByVal lojaId As Long, _
                                     ByVal modeloId As Long) As String
    BuildJsonImpressora = "{""identificador"": """ & identificador & _
                          """, ""loja_id"":" & lojaId & _
                          ", ""modelo_id"":" & modeloId & "}"
End Function

Private Function BuildJsonImpressoraPorLoja(ByVal identificador As String, _
                                            ByVal modeloId As Long) As String
    BuildJsonImpressoraPorLoja = "{""identificador"": """ & identificador & _
                                 """, ""modelo_id"":" & modeloId & "}"
End Function

Private Function BuildJsonContador(ByVal identificador As String, _
                                   ByVal contador As Long) As String
    BuildJsonContador = "{""identificador"": """ & identificador & _
                       """, ""contador"":" & contador & "}"
End Function

'*******************************************************************************
' Inicialização e Limpeza
'*******************************************************************************

Private Sub Class_Initialize()
    m_Token = ""
    m_BaseUrl = ""
    m_LastError = ""
    m_LastStatusCode = 0
End Sub

Private Sub Class_Terminate()
    m_Token = ""
    m_LastError = ""
End Sub
