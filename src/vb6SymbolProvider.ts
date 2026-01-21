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
        
        // Retorna os símbolos parseados
        return this.parser.parse(document);
    }
}
