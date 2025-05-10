int nvgCopyImage(NVGcontext* dst, NVGcontext* src, int image)
{
   if( dst == src)
      return( image);

   assert( dst->shareid);
   assert( dst->shareid == src->shareid);

	return dst->params.renderCopyTexture( dst->params.userPtr,
                                         src->params.userPtr,
                                         image);
}


static int glnvg__renderCopyTexture(void* dstptr, void *srcptr, int image)
{
	GLNVGcontext* dstgl = (GLNVGcontext*)dstptr;
	GLNVGcontext* srcgl = (GLNVGcontext*)srcptr;
	GLNVGtexture* tex;
	GLNVGtexture* srctex;

	srctex = glnvg__findTexture(srcgl, image);
   if( ! srctex)
      return( 0);

	tex  = glnvg__allocTexture(dstgl);
   *tex = *srctex;

	return tex->id;
}



struct NVGcontext {
	NVGparams params;
	float* commands;
	int ccommands;
	int ncommands;
	float commandx, commandy;
	NVGstate states[NVG_MAX_STATES];
	int nstates;
	NVGpathCache* cache;
	float tessTol;
	float distTol;
	float fringeWidth;
	float devicePxRatio;
	struct FONScontext* fs;
	int fontImages[NVG_MAX_FONTIMAGES];
	int fontImageIdx;
	int drawCallCount;
	int fillTriCount;
	int strokeTriCount;
	int textTriCount;
	int shareID;   // just for consistency checking
};



void nvgShareId(NVGcontext* ctx, int shareID)
{
	ctxt->shareID = shareID;
}
