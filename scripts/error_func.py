import numpy as np


def error(sol, sol_ref, eps, mesh, tag, save_tag=None, save_tag_array=None):

    if tag == "scalar":

        abs_error = np.abs(sol - sol_ref)

        abs_error_max = np.max(abs_error)
        abs_error_mean = np.mean(abs_error)
        
        print("")
        print(f"  * Max. absolute error : {abs_error_max:.3e}.")
        print(f"  * Avg. absolute error : {abs_error_mean:.3e}.")

        denom = np.abs(sol_ref)
        num = np.abs(sol - sol_ref)
        
        rel_error = np.where(denom > eps, num * 100 / denom, np.nan)
        
        rel_error_max = np.max(rel_error[np.isfinite(rel_error)])
        rel_error_mean = np.mean(rel_error[np.isfinite(rel_error)])
    
        print("")
        print(f"  * Max. relative error : {rel_error_max:.3e} %.")
        print(f"  * Avg. relative error : {rel_error_mean:.3e} %.")
        
        
        if save_tag != None:
            mesh[f"abs_error_{save_tag}"] = abs_error
            mesh[f"rel_error_{save_tag}"] = rel_error
        
        if save_tag_array != None:
            mesh = np.concatenate((mesh, rel_error), axis=1)

    elif tag == "vector":

        directions = ["x", "y", "z"]

        abs_error = np.zeros((len(sol), 3))
        rel_error = np.zeros((len(sol), 3))

        for i, direction in enumerate(directions):

            sol_dir = sol[:, i]
            sol_ref_dir = sol_ref[:, i]
            
            abs_error_dir = np.abs(sol_dir - sol_ref_dir)
            
            abs_error_max = np.max(abs_error_dir)
            abs_error_mean = np.mean(abs_error_dir)
            
            print("")
            print(f"  * Max. absolute error in {direction} direction  : {abs_error_max:.3e}.")
            print(f"  * Avg. absolute error in {direction} direction  : {abs_error_mean:.3e}.")

            abs_error[:, i] = abs_error_dir
            
            denom = np.abs(sol_ref_dir)
            num = np.abs(sol_dir - sol_ref_dir)
            rel_error_dir = np.where(denom > eps, num * 100 / denom, np.nan)
            
            rel_error_max = np.max(rel_error_dir[np.isfinite(rel_error_dir)])
            rel_error_mean = np.mean(rel_error_dir[np.isfinite(rel_error_dir)])
            
            print("")
            print(f"  * Max. relative error in {direction} direction : {rel_error_max:.3e} %.")
            print(f"  * Avg. relative error in {direction} direction : {rel_error_mean:.3e} %.")

            rel_error[:, i] = rel_error_dir
            
        
        if save_tag != None:
            mesh[f"abs_error_{save_tag}"] = abs_error
            mesh[f"rel_error_{save_tag}"] = rel_error

        if save_tag_array != None:
            mesh = np.concatenate((mesh, rel_error), axis=1)

    return mesh