#' apply a gating method to the \code{GatingSet}
#' 
#' When interacting with the existing gated data, this function provides the alternative way to interact with he GatingSet 
#' by supplying the gating description directly through arguments without the need to write the compelete
#' csv gating template.   
#'
#' @param gs GatingSet or GatingSetList
#' @param alias,pop,parent,dims,gating_method,gating_args,collapseDataForGating,groupBy,preprocessing_method,preprocessing_args see details in \link[openCyto:gatingTemplate-class]{gatingTemplate}
#' @param ... other arguments
#' \itemize{
#'      \item{mc.cores}{ passed to \code{multicore} package for parallel computing}
#'      \item{parallel_type}{  \code{character} specifying the parallel type. The valid options are "none", "multicore", "cluster".}
#'      \item{cl}{ \code{cluster} object passed to \code{parallel} package (when \code{parallel_type} is "cluster")}
#'      }
#' @export 
#' @examples 
#' \dontrun{
#'  # add quad gates 
#'  add_pop(gs, gating_method = "mindensity", dims = "CCR7,CD45RA", parent = "cd4-cd8+", pop = "CCR7+/-CD45RA+/-")
#' 
#' # polyfunctional gates (boolean combinations of exsiting marginal gates)
#' add_pop(gs, gating_method = "polyFunctions", parent = "cd8", gating_args = "cd8/IFNg:cd8/IL2:cd8/TNFa")
#' 
#' #boolGate method
#' add_pop(gs, alias = "IL2orIFNg", gating_method = "boolGate", parent = "cd4", gating_args = "cd4/IL2|cd4/IFNg") 
#' }
add_pop <- function(gs, alias = "*"
                      , pop = "A+"
                      , parent
                      , dims = NA
                      , gating_method
                      , gating_args = NA
                      , collapseDataForGating = NA
                      , groupBy = NA
                      , preprocessing_method = NA
                      , preprocessing_args = NA
                      , ...) {
      
      #still check this new pop                     
      .validity_check_alias(alias)
                    
      #generate the dummy template based on the existing gating hierarchy
      dt <- as.data.table(templateGen(gs[[1]]))
      if(nrow(dt)>0){
        #Can't use the existing dummy_gate since it is dedicated as dummy_ref gate generated by multiPos entry (alias = '*')
        #which requires the ref node to be explicitly supplied
        dt[, gating_method := "dummy"]
      }
      
      thisRow <- data.table(alias = alias
              , pop = pop
              , parent = parent
              , dims = dims
              , gating_method = gating_method
              , gating_args =  gating_args
              , collapseDataForGating = collapseDataForGating
              , groupBy = groupBy
              , preprocessing_method = preprocessing_method
              , preprocessing_args = preprocessing_args
             )
      if(nrow(thisRow)>1)
        stop("Can't add multiple rows!Please make sure each argument is of length 1.")
      #there's a weird bug where rbinding a 0-row dt and a non-zero row dt returns > 4M rows.
      if(nrow(dt)>0){       
        dt <- rbind(dt, thisRow)   
      }else{
        dt = thisRow
      }
      
      tmp <- tempfile(fileext = ".csv")
      write.csv(dt, tmp, row.names = F)
      
      #skip the validity check on the other entries
      suppressMessages(gt <- gatingTemplate(tmp, strict = FALSE))
      message("...")
      suppressMessages(gating(gt, gs, ...))
      message("done")
      invisible(thisRow)
    }