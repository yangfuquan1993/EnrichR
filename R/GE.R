#' GO Enrichment analysis function
#' @param  df: DGE files (DESeq2 result files) or vector contains gene names
#' @param  GO_FILE: GO annotation data
#' @param  filenam: output filename
#' @param  gene.cutoff: the cut-off value for select DGE
#' @export
#' @author Kai Guo
GE<-function(df,GO_FILE,OP="BP",gene.cutoff=0.01,minSize=2,maxSize=500,keepRich=TRUE,filename=NULL,padj.method="BH"){
  go2gene<-sf(GO_FILE)
  all_go<-.get_go_dat(ont=OP)
  go2gene<-go2gene[names(go2gene)%in%all_go$GOID];
  gene2go<-reverseList(go2gene)
  if(is.data.frame(df)){
    IGE<-rownames(df)[df$padj<gene.cutoff]
  }else{
    IGE=as.vector(df)
  }
  fgene2go<-gene2go[IGE];
  fgo2gene<-reverseList(fgene2go)
  k=name_table(fgo2gene);
  n=sum(!is.na(names(fgene2go)))
  IGO<-names(fgo2gene);
  N=length(unique(unlist(go2gene)));
  M<-name_table(go2gene[IGO])
  rhs<-hyper_bench_vector(k,M,N,n)
  lhs<-p.adjust(rhs,method=padj.method)
  rhs_an<-all_go[all_go$GOID%in%names(rhs),1:2]
  rownames(rhs_an)<-rhs_an[,1]
  rhs_gene<-unlist(lapply(fgo2gene, function(x)paste(unique(x),sep="",collapse = ",")))
  resultFis<-data.frame("Annot"=rhs_an$GOID,"Term"=rhs_an[names(rhs),"TERM"],"Annotated"=M[rhs_an$GOID],
                        "Significant"=k[rhs_an$GOID],"Pvalue"=as.vector(rhs),"Padj"=lhs,
                        "GeneID"=rhs_gene[as.vector(rhs_an$GOID)])
  resultFis<-resultFis[order(resultFis$Pvalue),]
  resultFis<-resultFis[resultFis$Pvalue<0.05,]
  resultFis<-resultFis%>%dplyr::filter(Significant<=maxSize)
  if(keepRich==FALSE){
    resultFis<-resultFis%>%dplyr::filter(Significant>=minSize)
  }else{
    resultFis<-resultFis%>%dplyr::filter(Significant>=minSize|(Annotated/Significant)==1)
  }
  if(!is.null(filename)){
    write.table(resultFis,file=paste(filename,OP,"res.txt",sep="_"),sep="\t",quote=F,row.names=F)
  }
  return(resultFis);
}
#' Display GO enrichment result
#' @param  resultFis: GO ennrichment analysis result data.frame
#' @param  top: Number of Terms you want to display
#' @param  filenam: output filename
#' @param  pvalue.cutoff: the cut-off value for selecting Term
#' @param  padj.cutoff: the padj cut-off value for selecting Term
#' @export
#' @author Kai Guo
GE.plot<-function(resultFis,top=50,pvalue.cutoff=0.05,order=FALSE,fontsize.x=10,fontsize.y=10,fontsize.text=3,angle=75,padj.cutoff=NULL,usePadj=TRUE,filename=NULL){
    require(ggplot2)
    if(!is.null(padj.cutoff)){
      resultFis<-resultFis[resultFis$Padj<padj.cutoff,]
    }else{
      resultFis<-resultFis[resultFis$Pvalue<pvalue.cutoff,]
    }
    if(nrow(resultFis)>=top){
      resultFis<-resultFis[1:top,]
    }
    if(max(resultFis$Significant/(resultFis$Annotated+0.1))<=1){
      yheight=max(resultFis$Significant/resultFis$Annotated)+0.1
    }else{
      yheight=1
    }
    if(order==TRUE){
      resultFis$rich<-as.numeric(resultFis$Significant)/as.numeric(resultFis$Annotated)
      resultFis$Term<-factor(resultFis$Term,levels=resultFis$Term[order(resultFis$rich)])
    }
    if(usePadj==FALSE){
      p<-ggplot(resultFis,aes(x=Term,y=round(as.numeric(Significant/Annotated),2)))+geom_bar(stat="identity",aes(fill=-log10(as.numeric(Pvalue))))
      p<-p+scale_fill_gradient(low="lightpink",high="red")+theme_light()+
        theme(axis.text.y=element_text(face="bold",size=fontsize.y),axis.text.x=element_text(face="bold",color="black",size=fontsize.x,angle=angle,vjust=1,hjust=1))+labs(fill="-log10(Pvalue)")
      p<-p+geom_text(aes(label=Significant),vjust=-0.3,size=fontsize.text)+xlab("Annotation")+ylab("Rich Factor")+ylim(0,yheight)
      print(p)
    }else{
    p<-ggplot(resultFis,aes(x=Term,y=round(as.numeric(Significant/Annotated),2)))+geom_bar(stat="identity",aes(fill=-log10(as.numeric(Padj))))
    p<-p+scale_fill_gradient2(low="lightpink",high="red")+theme_light()+
      theme(axis.text.y=element_text(face="bold",size=fontsize.y),axis.text.x=element_text(face="bold",color="black",size=fontsize.x,angle=angle,vjust=1,hjust=1))+labs(fill="-log10(Padj)")
    p<-p+geom_text(aes(label=Significant),vjust=-0.3,size=fontsize.text)+xlab("Annotation")+ylab("Rich Factor")+ylim(0,yheight)
    print(p)
    }
    if(!is.null(filename)){
      ggsave(p,file=paste(filename,OP,"enrich.pdf",sep="_"),width=10,height=8)
    }
}

