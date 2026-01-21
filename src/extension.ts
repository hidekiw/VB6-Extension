import * as vscode from 'vscode';
import { VB6DocumentSymbolProvider } from './vb6SymbolProvider';

/**
 * Ativa a extensão VB6 Outline
 * Registra o Document Symbol Provider para arquivos VB6
 */
export function activate(context: vscode.ExtensionContext) {
	console.log('VB6 Outline extension is now active!');

	// Seletor de documentos VB6 (.cls, .bas, .frm)
	const VB6_SELECTOR: vscode.DocumentSelector = [
		{ language: 'vb', scheme: 'file', pattern: '**/*.cls' },
		{ language: 'vb', scheme: 'file', pattern: '**/*.bas' },
		{ language: 'vb', scheme: 'file', pattern: '**/*.frm' },
		{ scheme: 'file', pattern: '**/*.cls' },
		{ scheme: 'file', pattern: '**/*.bas' },
		{ scheme: 'file', pattern: '**/*.frm' }
	];

	// Registra o Document Symbol Provider
	const symbolProvider = new VB6DocumentSymbolProvider();
	const disposable = vscode.languages.registerDocumentSymbolProvider(
		VB6_SELECTOR,
		symbolProvider,
		{ label: 'VB6' }
	);

	context.subscriptions.push(disposable);
}

export function deactivate() {}
