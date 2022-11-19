export declare const lexer: (source: string) => unknown[];
export declare const parser: (tokens: unknown[]) => unknown;
export declare const compiler: (ast: unknown) => { bytes: number[]; constants: unknown[] };
export declare const vm: {
	run: (bytes: number[], constants: unknown[]) => unknown;
};
