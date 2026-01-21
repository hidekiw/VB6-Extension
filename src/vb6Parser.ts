import * as vscode from 'vscode';

/**
 * Parser para arquivos Visual Basic 6
 * Extrai símbolos (classes, módulos, funções, propriedades, etc.)
 */
export class VB6Parser {
    
    /**
     * Analisa um documento VB6 e retorna os símbolos encontrados
     */
    public parse(document: vscode.TextDocument): vscode.DocumentSymbol[] {
        const symbols: vscode.DocumentSymbol[] = [];
        const text = document.getText();
        const lines = text.split('\n');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            const lineNumber = i;

            // Ignora linhas vazias e comentários
            if (!line || line.startsWith("'")) {
                continue;
            }

            // Public/Private Sub
            const subMatch = line.match(/^(Public|Private|Friend)?\s*(Static)?\s*Sub\s+(\w+)/i);
            if (subMatch) {
                const name = subMatch[3];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Method,
                    lineNumber,
                    this.findEndOfBlock(lines, i, 'Sub'),
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Public/Private Function
            const functionMatch = line.match(/^(Public|Private|Friend)?\s*(Static)?\s*Function\s+(\w+)/i);
            if (functionMatch) {
                const name = functionMatch[3];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Function,
                    lineNumber,
                    this.findEndOfBlock(lines, i, 'Function'),
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Property Get/Let/Set
            const propertyMatch = line.match(/^(Public|Private|Friend)?\s*Property\s+(Get|Let|Set)\s+(\w+)/i);
            if (propertyMatch) {
                const propType = propertyMatch[2];
                const name = propertyMatch[3];
                const symbol = this.createSymbol(
                    `${name} (${propType})`,
                    vscode.SymbolKind.Property,
                    lineNumber,
                    this.findEndOfBlock(lines, i, 'Property'),
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Type declaration
            const typeMatch = line.match(/^(Public|Private)?\s*Type\s+(\w+)/i);
            if (typeMatch) {
                const name = typeMatch[2];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Struct,
                    lineNumber,
                    this.findEndOfBlock(lines, i, 'Type'),
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Enum declaration
            const enumMatch = line.match(/^(Public|Private)?\s*Enum\s+(\w+)/i);
            if (enumMatch) {
                const name = enumMatch[2];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Enum,
                    lineNumber,
                    this.findEndOfBlock(lines, i, 'Enum'),
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Const declaration
            const constMatch = line.match(/^(Public|Private|Friend)?\s*Const\s+(\w+)/i);
            if (constMatch) {
                const name = constMatch[2];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Constant,
                    lineNumber,
                    lineNumber,
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Variable declaration (Dim, Public, Private)
            const varMatch = line.match(/^(Dim|Public|Private|Friend)\s+(\w+)/i);
            if (varMatch) {
                const name = varMatch[2];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Variable,
                    lineNumber,
                    lineNumber,
                    document
                );
                symbols.push(symbol);
                continue;
            }

            // Class name (from Attribute VB_Name)
            const classNameMatch = line.match(/^Attribute\s+VB_Name\s*=\s*"(\w+)"/i);
            if (classNameMatch) {
                const name = classNameMatch[1];
                const symbol = this.createSymbol(
                    name,
                    vscode.SymbolKind.Class,
                    lineNumber,
                    lineNumber,
                    document
                );
                // Adiciona no início da lista
                symbols.unshift(symbol);
                continue;
            }
        }

        return symbols;
    }

    /**
     * Cria um DocumentSymbol
     */
    private createSymbol(
        name: string,
        kind: vscode.SymbolKind,
        startLine: number,
        endLine: number,
        document: vscode.TextDocument
    ): vscode.DocumentSymbol {
        const startPos = new vscode.Position(startLine, 0);
        const endPos = new vscode.Position(endLine, document.lineAt(endLine).text.length);
        const range = new vscode.Range(startPos, endPos);
        
        // Selection range aponta para o nome do símbolo na linha de declaração
        const selectionRange = new vscode.Range(startPos, startPos.translate(0, name.length));

        return new vscode.DocumentSymbol(
            name,
            '',
            kind,
            range,
            selectionRange
        );
    }

    /**
     * Encontra o final de um bloco (End Sub, End Function, etc.)
     */
    private findEndOfBlock(lines: string[], startLine: number, blockType: string): number {
        const endPattern = new RegExp(`^End\\s+${blockType}`, 'i');
        
        for (let i = startLine + 1; i < lines.length; i++) {
            const line = lines[i].trim();
            if (endPattern.test(line)) {
                return i;
            }
        }
        
        // Se não encontrou End, retorna a próxima linha vazia ou fim do arquivo
        for (let i = startLine + 1; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith("'")) {
                return i - 1;
            }
        }
        
        return Math.min(startLine + 10, lines.length - 1);
    }
}
