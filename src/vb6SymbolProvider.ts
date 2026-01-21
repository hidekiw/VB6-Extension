import * as vscode from 'vscode';
import { VB6Parser } from './vb6Parser';

/**
 * Document Symbol Provider para arquivos VB6
 */
export class VB6DocumentSymbolProvider implements vscode.DocumentSymbolProvider {
    private parser: VB6Parser;

    constructor() {
        this.parser = new VB6Parser();
    }

    /**
     * Fornece os símbolos do documento para o VS Code
     */
    public provideDocumentSymbols(
        document: vscode.TextDocument,
        token: vscode.CancellationToken
    ): vscode.ProviderResult<vscode.DocumentSymbol[]> {
        console.log('=== provideDocumentSymbols called ===');
        console.log('Document URI:', document.uri.toString());
        console.log('Document languageId:', document.languageId);
        console.log('Document fileName:', document.fileName);
        
        // Retorna os símbolos parseados
        const symbols = this.parser.parse(document);
        console.log('Parsed symbols count:', symbols?.length || 0);
        if (symbols && symbols.length > 0) {
            console.log('First symbol:', symbols[0].name, symbols[0].kind);
        }
        return symbols;
    }
}
