# Must be executed BEFORE rgl is loaded on headless devices.
options(rgl.useNULL=TRUE)

library(shiny)
library(ggplot2)
library(FactoMineR)
library(scatterplot3d)
library(DT)
library(plotly)
library("RColorBrewer")
library(ggrepel)

factor2numeric<-function(x){
  x[,1]<-as.factor(x[,1])
  for (i in 2:ncol(x)){
    x[,i]<-as.numeric(x[,i])
  }
  return(x)
}

options(shiny.maxRequestSize=100*1024^2) # max file size is 100Mb
shinyServer(function(input,output,session){

 datasetInput <- reactive({ 
                            
example<-read.table("data/test.txt",header=F,sep="\t",row.names=1)
#example<-read.table("/srv/shiny-server/PCAonline/test.txt",header=F,sep="\t",row.names=1)
 	inFile <- input$file1
  if (!is.null(inFile)){
       
      data<-read.table(inFile$datapath, header=input$header, sep=input$sep, quote=input$quote,row.names=1,stringsAsFactors=F) 
      data<-factor2numeric(data)
   			
   
  }
 switch(input$dataset,
          "example" = example,
          "upload" = data
          )	
	})

 # output upload dataset or example dataset  
output$summary <- DT::renderDataTable(datasetInput())
output$dim<-renderPrint({
   a<-datasetInput()
  dim(a)
})


  
output$pcatable<-renderTable({
     a<-datasetInput()
     pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
     if(input$pcaresult == 'eigenvalues'){
     pca$eig
     }else if(input$pcaresult == 'vcoord'){
     pca$var$coord
     }else if(input$pcaresult == 'vcor'){
     pca$var$cor
     }else if(input$pcaresult == 'vcos2'){
     pca$var$cos2
     }else if(input$pcaresult == 'vcontri'){
     pca$var$contrib
     }else if(input$pcaresult == 'icoord'){
     pca$ind$coord
     }else if(input$pcaresult == 'icos2'){
     pca$ind$cos2
     }else if(input$pcaresult == 'icontri'){
     pca$ind$contrib
     }else{
        return(NULL)
     }
})

output$test<-renderPrint({
      a<-datasetInput()
      str(a)

})
output$pcasum<-renderPrint({
     a<-datasetInput()
     a<-factor2numeric(a)
     pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
     if(input$pcaresult == 'call'){
     pca$call
     }else if(input$pcaresult == 'crw'){
     pca$call$row.w
     }else if(input$pcaresult == 'ccw'){
     pca$call$col.w
     }else if(input$pcaresult == 'variables'){
     pca$var
     }else if(input$pcaresult == 'cc'){
     pca$call$centre
     }else if(input$pcaresult == 'cet'){
     pca$call$ecart.type
     }else if(input$pcaresult == 'individuals'){
     pca$ind
     }else {
     return(NULL)
     }
})


 #plot 2d picture

plotPCA2D<-reactive({
  a<-datasetInput()
  pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
  PC1 <- pca$ind$coord[,1]
  PC2 <- pca$ind$coord[,2]
  var.pc1<-round(pca$eig[1,2],digits = 1)
  var.pc2<-round(pca$eig[2,2],digits=1)
  xlabel<-paste("PC1(",var.pc1,"%)",sep="")
  ylabel<-paste("PC2(",var.pc2,"%)",sep="")
  
  plotdata <- data.frame(group=a[,1],PC1,PC2) 
  plotdata$group <- factor(plotdata$group)
  plot <- ggplot(plotdata, aes(PC1, PC2)) + 
    geom_point(aes(colour = group,shape = group),size = input$pointSize)+xlab(xlabel)+ylab(ylabel)
    
  
  if(input$showtext==TRUE){
    # plot=plot+geom_text(aes(label=rownames(plotdata)), size=5, hjust=0.5, vjust=-0.5)
    plot=plot+geom_text_repel(aes(PC1, PC2, label=rownames(plotdata)),size=5)
  }
  
  plot=plot+theme(panel.border = element_rect(linetype = "dashed")) + 
    theme_bw() + 
    theme(legend.text = element_text(colour="blue", size = 16, face ="bold")) + 
    theme(legend.title = element_text(colour="black", size=16, face="bold"))
  return(plot)
})
output$plotPCAtwoD <- renderPlot({
    print(plotPCA2D())
},width="auto",height="auto") 

################################
#download 2D plot option    
      output$downloadDataPNG <- downloadHandler(
        filename = function() {
          paste("output", Sys.time(), '.png', sep='')
        },
        
        content = function(file) {
          png(file, type="cairo",units="in",width = 10, height = 10,pointsize=5.2,res=300)
          #png(file=file, width = 600, height = 600, units = "px", pointsize = 12, bg = "white", res = NA)
          print(plotPCA2D())
          dev.off()
        },
        contentType = 'image/png'
      )
      
      
      output$downloadDataPDF <- downloadHandler(
        filename = function() {
          paste("output", Sys.time(), '.pdf', sep='')
        },
        
        content = function(file) {
          pdf(file)
          print(plotPCA2D())
          dev.off()
        },
        contentType = 'image/pdf'
      )
      
      output$downloadDataEPS <- downloadHandler(
        filename = function() {
          paste("output", Sys.time(), '.eps', sep='')
        },
        
        content = function(file) {
          setEPS()
          postscript(file, horizontal = FALSE, onefile = FALSE, paper = "special")
          print(plotPCA2D())
          dev.off()
        },
        contentType = 'image/eps'
      )
#################################



#print 3D plot 
output$plotPCAthreeDtext <- renderPlot({
a<-datasetInput()
     pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
     PC1 <- pca$ind$coord[,1]
     PC2 <- pca$ind$coord[,2]
     PC3 <- pca$ind$coord[,3]
     plotdata <- data.frame(group=a[,1],PC1,PC2,PC3) 
     plotdata$group <- factor(plotdata$group)
     
     #create colorkey color
      plotdata$colorxold <- as.numeric(plotdata$group)
     colorlist=c("red","darkgreen","blue","yellow","purple")
     #define point color
     for(i in 1:length(plotdata$colorxold)){
        plotdata$colorx[i] <- colorlist[plotdata$colorxold[i]]
     }
      colory <- as.character(unique(plotdata$group))
     #colorz <- as.numeric(unique(plotdata$group))
      colorz <- unique(plotdata$colorx)
      
# create column indicating point color
  with(plotdata, {
        s3d <- scatterplot3d(PC1, PC2, PC3,        # x y and z axis
                  color=colorx, pch=19,        # circle color indicates no. of cylinders
                  type=input$plottype, lty.hplot=2,       # lines to the horizontal plane
                  scale.y=.75,                 # scale y axis (reduce by 25%)
                  main="3-D Scatterplot For PCA analysis",
                  xlab="PC1",
                  ylab="PC2",
                  zlab="PC3",angle=input$angle)
         s3d.coords <- s3d$xyz.convert(PC1, PC2, PC3)
         text(s3d.coords$x, s3d.coords$y,     # x and y coordinates
              labels=row.names(plotdata),col=colorx,       # text to plot
              pos=4, cex=input$threeDtextSize)                  # shrink text 50% and place to right of points)
              # add the legend
         legend("topleft", inset=.05,      # location and inset
              bty="n", cex=1,              # suppress legend box, shrink text 50%
              title="Sample Type",
              colory, fill=colorz)
     })

},width=800,height=800)


#print 3D plot 
output$plotPCAthreeD <- renderPlot({
     a<-datasetInput()
     pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
     PC1 <- pca$ind$coord[,1]
     PC2 <- pca$ind$coord[,2]
     PC3 <- pca$ind$coord[,3]
     plotdata <- data.frame(group=a[,1],PC1,PC2,PC3) 
     plotdata$group <- factor(plotdata$group)
                    #create colorkey color
     plotdata$colorxold <- as.numeric(plotdata$group)
     colorlist=c("red","darkgreen","blue","yellow","purple","black","gray")
     #define point color
     for(i in 1:length(plotdata$colorxold)){
        plotdata$colorx[i] <- colorlist[plotdata$colorxold[i]]
     }
      
     colory <- as.character(unique(plotdata$group))
     #colorz <- as.numeric(unique(plotdata$group))
      colorz <- unique(plotdata$colorx)
            # create column indicating point color
with(plotdata, {
        s3d <- scatterplot3d(PC1, PC2, PC3,        # x y and z axis
                  color=colorx, pch=19,        # circle color indicates no. of cylinders
                  type=input$plottype, lty.hplot=2,       # lines to the horizontal plane
                  scale.y=.75,                 # scale y axis (reduce by 25%)
                  main="3-D Scatterplot For PCA analysis",
                  xlab="PC1",
                  ylab="PC2",
                  zlab="PC3",angle=input$angle)
# add the legend
        legend("topleft", inset=.05,      # location and inset
               bty="n", cex=1,              # suppress legend box, shrink text 50%
               title="Sample Type",
               colory, fill=colorz)
     })

},width="auto",height="auto")



output$downloadData <- downloadHandler(
  filename = function() {
    paste('plot-', Sys.Date(), '.png')
  },
  content = function(con) {
    a<-datasetInput()
     pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
     PC1 <- pca$ind$coord[,1]
     PC2 <- pca$ind$coord[,2]
     PC3 <- pca$ind$coord[,3]
     plotdata <- data.frame(group=a[,1],PC1,PC2,PC3) 
     plotdata$group <- factor(plotdata$group)
                    #create colorkey color
     plotdata$colorxold <- as.numeric(plotdata$group)
     colorlist=c("red","darkgreen","blue","yellow","purple")
     #define point color
     for(i in 1:length(plotdata$colorxold)){
        plotdata$colorx[i] <- colorlist[plotdata$colorxold[i]]
     }
      
     colory <- as.character(unique(plotdata$group))
     #colorz <- as.numeric(unique(plotdata$group))
      colorz <- unique(plotdata$colorx)
            # create column indicating point color
plot <- with(plotdata, {
        s3d <- scatterplot3d(PC1, PC2, PC3,        # x y and z axis
                  color=colorx, pch=19,        # circle color indicates no. of cylinders
                  type="h", lty.hplot=2,       # lines to the horizontal plane
                  scale.y=.75,                 # scale y axis (reduce by 25%)
                  main="3-D Scatterplot For PCA analysis",
                  xlab="PC1",
                  ylab="PC2",
                  zlab="PC3",angle=input$angle)
# add the legend
        legend("topleft", inset=.05,      # location and inset
               bty="n", cex=1,              # suppress legend box, shrink text 50%
               title="Sample Type",
               colory, fill=colorz)
     })

    png(plot,con)
  }
)
	
#plotly 
output$plotPCAthreeDInteractive  <- renderPlotly({
  a<-datasetInput()
  pca <-PCA(a[,2:ncol(a)], scale.unit=T, graph=F)
  PC1 <- pca$ind$coord[,1]
  PC2 <- pca$ind$coord[,2]
  PC3 <- pca$ind$coord[,3]
  plotdata <- data.frame(group=a[,1],PC1,PC2,PC3) 
  plotdata$group <- factor(plotdata$group)
  #create colorkey color
  plotdata$colorxold <- as.numeric(plotdata$group)
  colorlist=brewer.pal(length(unique(plotdata$group)), input$`3dcoloroption`)
   
  #define point color
  for(i in 1:length(plotdata$colorxold)){
    plotdata$colorx[i] <- colorlist[plotdata$colorxold[i]]
  }
  
  colory <- as.character(unique(plotdata$group))
  #colorz <- as.numeric(unique(plotdata$group))
  colorz <- unique(plotdata$colorx)
  # create column indicating point color
  p=plot_ly(plotdata, x = ~PC1, y = ~PC2, z = ~PC3, color = ~group, colors = colorlist) %>%
    add_markers() %>%
    layout(scene = list(xaxis = list(title = 'PC1'),
                        yaxis = list(title = 'PC2'),
                        zaxis = list(title = 'PC3')))
  
})


#color panel
output$colorpanel<-renderPlot({
  display.brewer.all(n=NULL, type="all", select=NULL, exact.n=TRUE)
})
})



