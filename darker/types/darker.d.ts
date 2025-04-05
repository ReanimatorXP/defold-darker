/** @noResolution */
declare module 'darker.darker' {
    /**
     * Message hash constants used for communicating with the darker module
     */
    export const MSG_SPOTLIGHT: hash;
    export const MSG_UPDATE_MASK: hash;
    export const MSG_REVERT_ORIGINAL_MATERIALS: hash;
    
    /**
     * Global properties exposed by the module
     */
    export var highlight_go_pred: any;
    export var highlight_go_mat: hash;
    export var mask_texture_sampler: string;
    export var script: url;
    
    /**
     * Initializes the darker module by creating render predicates and render targets
     */
    export function init(): void;
    
    /**
     * Reverts the materials of all targeted game objects back to their original materials
     */
    export function revert_original_materials(): void;
    
    /**
     * Applies highlight materials to all targeted game objects
     */
    export function apply_highlight_materials(): void;
    
    /**
     * Updates the spotlight mask for previously stored targets
     * @returns {boolean} True if mask was applied successfully, false otherwise
     */
    export function update_mask(): boolean;
    
    /**
     * Sets up spotlight effect for specified game objects
     * @param {Array<hash|string|url>|undefined} go_ids Array of game object IDs to highlight
     * @returns {boolean} True if spotlight was applied successfully, false otherwise
     */
    export function spotlight(go_ids: Array<hash | string | url> | undefined): boolean;
    
    /**
     * Draws the mask to the render target (called from render_script)
     */
    export function draw_mask(): void;
    
    /**
     * Gets the render target for the mask
     * @returns {userdata} The render target for the mask
     */
    export function get_mask_rt(): any;
    
    /**
     * Handles window resize events, updating the render target size
     */
    export function on_window_resized(): void;
}