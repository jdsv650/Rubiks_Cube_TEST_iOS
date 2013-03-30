/*
 
 File: ES1Renderer.m
 
 Abstract: The ES1Renderer class creates an OpenGL ES 1.1 context and draws 
 using OpenGL ES 1.1 functions.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
*/

#import "ES1Renderer.h"

#ifndef M_PI
#define M_PI 3.14159265
#endif
#define V1 1  //viewports 1-4
#define V2 2
#define V3 3
#define V4 4

//   [0] Black        [1] Blue              //[2] Green            [3] Orange
GLfloat colors[7][4] = {{0.0, 0.0, 0.0, 1.0},{0.0, 0.0, 1.0, 1.0}, {0.0, 1.0, 0.0, 1.0}, {1, 0.5, 0.0, 1.0},
    {1.0, 0.0, 0.0, 1.0},{1.0, 1.0, 0.0, 1.0},{1.0, 1.0, 1.0, 1.0}};
// [4] Red            [5]  Yellow          [6] White

//[0] lower left outer z  [1] upper left outer z  [2] upper right outer z  [3] lower right outer z
//[4] lower left inner z  [5] upper left inner z  [6] upper right inner z  [7] lower right inner z

GLfloat cubeVerts[8][3];

// Front[0] Right[1]   Down[2]   Up[3]    Back[4]    Left[5]
GLfloat faceVertsZ[6][4] = {{0,3,2,1},{2,3,7,6},{3,0,4,7},{1,2,6,5},{4,5,6,7},{5,4,0,1}};
// Front[0]   Right[1]  Down[2]   Up[3]    Back[4]   Left[5]
GLfloat faceVertsY[6][4] = {{1,2,6,5},{2,3,7,6},{0,3,2,1},{4,5,6,7},{3,0,4,7},{5,4,0,1}};
// Front[0]   Right[1]  Down[2]   Up[3]    Back[4]   Left[5]
GLfloat faceVertsX[6][4] = {{5,4,0,1},{0,3,2,1},{3,0,4,7},{1,2,6,5},{2,3,7,6},{4,5,6,7}};

struct cubeStruct {
    // Front[0] Right[1] Down[2]  Up[3]    Back[4]  Left[5]
	GLint faceColors[6];
};

struct cubeStruct cubes[27];

int cubeSize = 1;  //1
int space = 2;     //2
int rot = 1;

//static GLint ww = 200;  //500
//static GLint wh = 200;  //500
//static GLint savedww, savedwh;
static GLint lightingEnabled = 0;
//static GLint wireframe = 1;
static GLenum mode = GL_SMOOTH;
//static GLenum polygonMode = GL_FILL;  //no GL_FILL available
//static GLint fullscreen = 0;
//static GLfloat left, right, bottom, top;
//static GLfloat near = -2.0, far = 2.0;
//static GLfloat zoom = 10;
//static GLint lastX = 0, lastY = 0;
//static int mouseButton, currentModifiers;
//static GLfloat theta = 45.0, phi = 45.0;
static GLfloat eyeX=5, eyeY=5, eyeZ=5;
//static int radius = 20;
//static int animateX =0;
//static int animateY =0;
//static int animateZ =0;
//static int animateSlice1 = 0;
//static int animateSlice2 = 0;
//static int animateSlice3 = 0;
//static int animateSlice4 = 0;
//static int animateSlice5 = 0;
//static int animateSlice6 = 0;
//static int animateSlice7 = 0;
//static int animateSlice8 = 0;
//static int animateSlice9 = 0;
//static GLuint lensAngle = 60;  // for persp view
//static int texture = 0; //texture off
GLuint tex_2d = 0;

int rotMult = 1;  // + rotation multiplier
int waitTime = 33;
int cubeRot = 0;
int view=1;  //view=1 then V2=Bottom V3=Left V4=Back
//view=2 then V2=Top V3=Right V4=Front
int perspView=1;   //1 orig 2 opp view

@implementation ES1Renderer

// Create an ES 1.1 context
- (id <ESRenderer>) init
{
	if (self = [super init])
	{
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context])
		{
            [self release];
            return nil;
        }
		
		// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
		glGenFramebuffersOES(1, &defaultFramebuffer);
		glGenRenderbuffersOES(1, &colorRenderbuffer);
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
        
        //setup the cube
        [self myinit];
	}
	
	return self;
}


- (void) render {
    
   // Replace the implementation of this method to do your own custom drawing
    [EAGLContext setCurrentContext:context];
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glPushMatrix();
	
    glViewport(0,0,backingWidth, backingHeight);
    // glViewport(ww/2, 0, ww/2,wh/2);
	// glOrthof(left, right, bottom, top, near, far);
    
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluLookAt(eyeX, eyeY, eyeZ, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	[self drawCube:V1];
	glPopMatrix();
}


- (void) myinit
{
	GLfloat light_position[] = { 1.0, 0.0, 0.0, 0.0 };
	GLfloat light_position1[] = { 0.0, 1.0, 0.0, 0.0 };
    
	/* Change the color of the light */
	GLfloat white_light[] = { 1.0, 1.0, 1.0, 1.0 };
	GLfloat lmodel_ambient[] = { 0.3, 0.3, 0.3, 1.0 };
    
	glShadeModel(GL_SMOOTH);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glMatrixMode(GL_MODELVIEW);
	glClearColor(0.0, 0.0, 0.0, 1.0);
	//glColor3f(0.0, 0.0, 0.0);
	glLightfv(GL_LIGHT0, GL_POSITION, light_position);
	glLightfv(GL_LIGHT1, GL_POSITION, light_position1);
	/* Your specular light could be different */
	glLightfv(GL_LIGHT0, GL_SPECULAR, white_light);
	glLightfv(GL_LIGHT1, GL_SPECULAR, white_light);
	glLightfv(GL_LIGHT0, GL_AMBIENT, white_light);
	glLightfv(GL_LIGHT1, GL_AMBIENT, white_light);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, white_light);
	glLightfv(GL_LIGHT1, GL_DIFFUSE, white_light);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
    
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_LIGHT1);
	//glEnable(GL_AUTO_NORMAL);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
	initCubeVerts();
	buildCube(); // set up initial cube -- colors...
	lightingEnabled = 0;
}

void initCubeVerts() {      //initialize cube vertices
	// {{-cubeSize,-cubeSize,cubeSize},{-cubeSize,cubeSize,cubeSize},  {cubeSize,cubeSize,cubeSize},
    //  {cubeSize,-cubeSize,cubeSize} ,{-cubeSize,-cubeSize,-cubeSize},{-cubeSize,cubeSize,-cubeSize},
	//  {cubeSize,cubeSize,-cubeSize},{cubeSize,-cubeSize,-cubeSize} };
     
    //[0] lower left outer z  //[1] upper left outer z //[2] upper right outer z
    //[3] lower right outer z //[4] lower left inner z //[5] upper left inner z
    //[6] upper right inner z //[7] lower right inner z
    
	cubeVerts[0][0]= -cubeSize; cubeVerts[0][1]= -cubeSize; cubeVerts[0][2]=  cubeSize;
	cubeVerts[1][0]= -cubeSize; cubeVerts[1][1]=  cubeSize; cubeVerts[1][2]=  cubeSize;
	cubeVerts[2][0]=  cubeSize; cubeVerts[2][1]=  cubeSize; cubeVerts[2][2]=  cubeSize;
	cubeVerts[3][0]=  cubeSize; cubeVerts[3][1]= -cubeSize; cubeVerts[3][2]=  cubeSize;
	cubeVerts[4][0]= -cubeSize; cubeVerts[4][1]= -cubeSize; cubeVerts[4][2]= -cubeSize;
	cubeVerts[5][0]= -cubeSize; cubeVerts[5][1]=  cubeSize; cubeVerts[5][2]= -cubeSize;
	cubeVerts[6][0]=  cubeSize; cubeVerts[6][1]=  cubeSize; cubeVerts[6][2]= -cubeSize;
	cubeVerts[7][0]=  cubeSize; cubeVerts[7][1]= -cubeSize; cubeVerts[7][2]= -cubeSize;
}

void buildCube() //color cube at start/completed state
{
	//cube 1
	cubes[0].faceColors[0] = 0;  //F is black
	cubes[0].faceColors[1] = 0;  //R is black
	cubes[0].faceColors[2] = 0;  //D is black
	cubes[0].faceColors[3] = 4;  //U is red
	cubes[0].faceColors[4] = 5;  //B is yellow
	cubes[0].faceColors[5] = 1;  //L is blue
	//cube 2
	cubes[1].faceColors[0] = 0;  //F is black
	cubes[1].faceColors[1] = 0;  //R is black
	cubes[1].faceColors[2] = 0;  //D is black
	cubes[1].faceColors[3] = 4;  //U is red
	cubes[1].faceColors[4] = 5;  //B is yellow
	cubes[1].faceColors[5] = 0;  //L is black
	//cube 3
	cubes[2].faceColors[0] = 0;  //F is black
	cubes[2].faceColors[1] = 2;  //R is green
	cubes[2].faceColors[2] = 0;  //D is black
	cubes[2].faceColors[3] = 4;  //U is red
	cubes[2].faceColors[4] = 5;  //B is yellow
	cubes[2].faceColors[5] = 0;  //L is black
	//cube 4
	cubes[3].faceColors[0] = 0;  //F is black
	cubes[3].faceColors[1] = 0;  //R is black
	cubes[3].faceColors[2] = 0;  //D is black
	cubes[3].faceColors[3] = 0;  //U is black
	cubes[3].faceColors[4] = 5;  //B is yellow
	cubes[3].faceColors[5] = 1;  //L is blue
	//cube 5
	cubes[4].faceColors[0] = 0;  //F is black
	cubes[4].faceColors[1] = 0;  //R is black
	cubes[4].faceColors[2] = 0;  //D is black
	cubes[4].faceColors[3] = 0;  //U is black
	cubes[4].faceColors[4] = 5;  //B is yellow
	cubes[4].faceColors[5] = 0;  //L is black
	//cube 6
	cubes[5].faceColors[0] = 0;  //F is black
	cubes[5].faceColors[1] = 2;  //R is green
	cubes[5].faceColors[2] = 0;  //D is black
	cubes[5].faceColors[3] = 0;  //U is black
	cubes[5].faceColors[4] = 5;  //B is yellow
	cubes[5].faceColors[5] = 0;  //L is black
	//cube 7
	cubes[6].faceColors[0] = 0;  //F is black
	cubes[6].faceColors[1] = 0;  //R is black
	cubes[6].faceColors[2] = 3;  //D is orange
	cubes[6].faceColors[3] = 0;  //U is black
	cubes[6].faceColors[4] = 5;  //B is yellow
	cubes[6].faceColors[5] = 1;  //L is blue
	//cube 8
	cubes[7].faceColors[0] = 0;  //F is black
	cubes[7].faceColors[1] = 0;  //R is black
	cubes[7].faceColors[2] = 3;  //D is orange
	cubes[7].faceColors[3] = 0;  //U is black
	cubes[7].faceColors[4] = 5;  //B is yellow
	cubes[7].faceColors[5] = 0;  //L is black
	//cube 9
	cubes[8].faceColors[0] = 0;  //F is black
	cubes[8].faceColors[1] = 2;  //R is green
	cubes[8].faceColors[2] = 3;  //D is orange
	cubes[8].faceColors[3] = 0;  //U is black
	cubes[8].faceColors[4] = 5;  //B is yellow
	cubes[8].faceColors[5] = 0;  //L is black
	//cube 10
	cubes[9].faceColors[0] = 0;  //F is black
	cubes[9].faceColors[1] = 0;  //R is black
	cubes[9].faceColors[2] = 0;  //D is black
	cubes[9].faceColors[3] = 4;  //U is red
	cubes[9].faceColors[4] = 0;  //B is black
	cubes[9].faceColors[5] = 1;  //L is blue
	//cube 11
	cubes[10].faceColors[0] = 0;  //F is black
	cubes[10].faceColors[1] = 0;  //R is black
	cubes[10].faceColors[2] = 0;  //D is black
	cubes[10].faceColors[3] = 4;  //U is red
	cubes[10].faceColors[4] = 0;  //B is black
	cubes[10].faceColors[5] = 0;  //L is black
	//cube 12
	cubes[11].faceColors[0] = 0;  //F is black
	cubes[11].faceColors[1] = 2;  //R is green
	cubes[11].faceColors[2] = 0;  //D is black
	cubes[11].faceColors[3] = 4;  //U is red
	cubes[11].faceColors[4] = 0;  //B is black
	cubes[11].faceColors[5] = 0;  //L is black
	//cube 13
	cubes[12].faceColors[0] = 0;  //F is black
	cubes[12].faceColors[1] = 0;  //R is black
	cubes[12].faceColors[2] = 0;  //D is black
	cubes[12].faceColors[3] = 0;  //U is black
	cubes[12].faceColors[4] = 0;  //B is black
	cubes[12].faceColors[5] = 1;  //L is blue
	//cube 14
	cubes[13].faceColors[0] = 0;  //F is black
	cubes[13].faceColors[1] = 0;  //R is black
	cubes[13].faceColors[2] = 0;  //D is black
	cubes[13].faceColors[3] = 0;  //U is black
	cubes[13].faceColors[4] = 0;  //B is black
	cubes[13].faceColors[5] = 0;  //L is black
	//cube 15
	cubes[14].faceColors[0] = 0;  //F is black
	cubes[14].faceColors[1] = 2;  //R is green
	cubes[14].faceColors[2] = 0;  //D is black
	cubes[14].faceColors[3] = 0;  //U is black
	cubes[14].faceColors[4] = 0;  //B is black
	cubes[14].faceColors[5] = 0;  //L is black
	//cube 16
	cubes[15].faceColors[0] = 0;  //F is black
	cubes[15].faceColors[1] = 0;  //R is black
	cubes[15].faceColors[2] = 3;  //D is orange
	cubes[15].faceColors[3] = 0;  //U is black
	cubes[15].faceColors[4] = 0;  //B is black
	cubes[15].faceColors[5] = 1;  //L is blue
	//cube 17
	cubes[16].faceColors[0] = 0;  //F is black
	cubes[16].faceColors[1] = 0;  //R is black
	cubes[16].faceColors[2] = 3;  //D is orange
	cubes[16].faceColors[3] = 0;  //U is black
	cubes[16].faceColors[4] = 0;  //B is yellow
	cubes[16].faceColors[5] = 0;  //L is black
	//cube 18
	cubes[17].faceColors[0] = 0;  //F is black
	cubes[17].faceColors[1] = 2;  //R is green
	cubes[17].faceColors[2] = 3;  //D is orange
	cubes[17].faceColors[3] = 0;  //U is black
	cubes[17].faceColors[4] = 0;  //B is yellow
	cubes[17].faceColors[5] = 0;  //L is black
	//cube 19
	cubes[18].faceColors[0] = 6;  //F is white
	cubes[18].faceColors[1] = 0;  //R is black
	cubes[18].faceColors[2] = 0;  //D is black
	cubes[18].faceColors[3] = 4;  //U is red
	cubes[18].faceColors[4] = 0;  //B is black
	cubes[18].faceColors[5] = 1;  //L is blue
	//cube 20
	cubes[19].faceColors[0] = 6;  //F is white
	cubes[19].faceColors[1] = 0;  //R is black
	cubes[19].faceColors[2] = 0;  //D is black
	cubes[19].faceColors[3] = 4;  //U is red
	cubes[19].faceColors[4] = 0;  //B is black
	cubes[19].faceColors[5] = 0;  //L is blue
	//cube 21
	cubes[20].faceColors[0] = 6;  //F is white
	cubes[20].faceColors[1] = 2;  //R is green
	cubes[20].faceColors[2] = 0;  //D is black
	cubes[20].faceColors[3] = 4;  //U is red
	cubes[20].faceColors[4] = 0;  //B is black
	cubes[20].faceColors[5] = 0;  //L is black
	//cube 22
	cubes[21].faceColors[0] = 6;  //F is white
	cubes[21].faceColors[1] = 0;  //R is black
	cubes[21].faceColors[2] = 0;  //D is black
	cubes[21].faceColors[3] = 0;  //U is black
	cubes[21].faceColors[4] = 0;  //B is black
	cubes[21].faceColors[5] = 1;  //L is blue
	//cube 23
	cubes[22].faceColors[0] = 6;  //F is white
	cubes[22].faceColors[1] = 0;  //R is black
	cubes[22].faceColors[2] = 0;  //D is black
	cubes[22].faceColors[3] = 0;  //U is black
	cubes[22].faceColors[4] = 0;  //B is black
	cubes[22].faceColors[5] = 0;  //L is black
	//cube 24
	cubes[23].faceColors[0] = 6;  //F is white
	cubes[23].faceColors[1] = 2;  //R is green
	cubes[23].faceColors[2] = 0;  //D is black
	cubes[23].faceColors[3] = 0;  //U is black
	cubes[23].faceColors[4] = 0;  //B is black
	cubes[23].faceColors[5] = 0;  //L is black
	//cube 25
	cubes[24].faceColors[0] = 6;  //F is white
	cubes[24].faceColors[1] = 0;  //R is black
	cubes[24].faceColors[2] = 3;  //D is orange
	cubes[24].faceColors[3] = 0;  //U is black
	cubes[24].faceColors[4] = 0;  //B is black
	cubes[24].faceColors[5] = 1;  //L is blue
	//cube 26
	cubes[25].faceColors[0] = 6;  //F is white
	cubes[25].faceColors[1] = 0;  //R is black
	cubes[25].faceColors[2] = 3;  //D is orange
	cubes[25].faceColors[3] = 0;  //U is black
	cubes[25].faceColors[4] = 0;  //B is black
	cubes[25].faceColors[5] = 0;  //L is black
	//cube 27
	cubes[26].faceColors[0] = 6;  //F is white
	cubes[26].faceColors[1] = 2;  //R is green
	cubes[26].faceColors[2] = 3;  //D is orange
	cubes[26].faceColors[3] = 0;  //U is black
	cubes[26].faceColors[4] = 0;  //B is yellow
	cubes[26].faceColors[5] = 0;  //L is black
} // end buildCube()


- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer
{	
	// Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void) drawZSlice:(int) num{  //draw 1 of the Z slices
	int cubeNum=1;
    
	if(num==1)
		cubeNum=1;
	else if(num==2)  //slice 2 10-18
		cubeNum=10;
	else if(num==3)  //slice 3 19-27
		cubeNum=19;
	glPushMatrix();
	glTranslatef(-(cubeSize+space), cubeSize+space ,0); //row1 col1 cube
	[self drawMiniCubeZ:cubeNum];           // slice num 1 2 or 3  -- slice num *
	glTranslatef(cubeSize+space,0,0);  //row1 col2 cube
	[self drawMiniCubeZ:(cubeNum+1)];
	glTranslatef(cubeSize+space,0,0);  //row1 col3 cube
	[self drawMiniCubeZ:(cubeNum+2) ];
	glTranslatef(-2*(cubeSize+space), -(cubeSize+space),0);  //row2 col1 cube
	[self drawMiniCubeZ:(cubeNum+3) ];
	glTranslatef(cubeSize+space,0,0); //row2 col2 cube  -- center cube
	[self drawMiniCubeZ:(cubeNum+4) ];
	glTranslatef(cubeSize+space,0,0); //row2 col3 cube
	[self drawMiniCubeZ:(cubeNum+5) ];
	glTranslatef(-2*(cubeSize+space), -(cubeSize+space),0);  //row3 col1 cube
	[self drawMiniCubeZ:(cubeNum+6) ];
	glTranslatef(cubeSize+space,0,0); //row3 col2 cube
	[self drawMiniCubeZ:(cubeNum+7) ];
	glTranslatef(cubeSize+space,0,0); //row3 col3 cube
	[self drawMiniCubeZ:(cubeNum+8) ];
	glPopMatrix();
}

- (void) drawYSlice:(int) num {  //draw one of the Y slices (stacks)
	int cubeArray[9];
    
	if(num==4) {		 //slice 4(or stack 1)
		cubeArray[0]= 19;
		cubeArray[1]= 20;
		cubeArray[2]= 21;
		cubeArray[3]= 10;
		cubeArray[4]= 11;
		cubeArray[5]= 12;
		cubeArray[6]= 1;
		cubeArray[7]= 2;
		cubeArray[8]= 3;
	}
	else if(num==5) { //slice 5 (or stack 2)
		cubeArray[0]= 22;
		cubeArray[1]= 23;
		cubeArray[2]= 24;
		cubeArray[3]= 13;
		cubeArray[4]= 14;
		cubeArray[5]= 15;
		cubeArray[6]= 4;
		cubeArray[7]= 5;
		cubeArray[8]= 6;
	}
	else if(num==6) { //slice 6 (or stack 3)
		cubeArray[0]= 25;
		cubeArray[1]= 26;
		cubeArray[2]= 27;
		cubeArray[3]= 16;
		cubeArray[4]= 17;
		cubeArray[5]= 18;
		cubeArray[6]= 7;
		cubeArray[7]= 8;
		cubeArray[8]= 9;
	}
    
	glPushMatrix();
	glTranslatef(-(cubeSize+space), cubeSize+space ,0); //row1 col1 cube
	[self drawMiniCubeY:(cubeArray[0]) ];           // slice num 4 5 or 6
	glTranslatef(cubeSize+space,0,0);  //row1 col2 cube
	[self drawMiniCubeY:(cubeArray[1]) ];
	glTranslatef(cubeSize+space,0,0);  //row1 col3 cube
	[self drawMiniCubeY:(cubeArray[2]) ];
	glTranslatef(-2*(cubeSize+space), -(cubeSize+space),0);  //row2 col1 cube
	[self drawMiniCubeY:(cubeArray[3]) ];
	glTranslatef(cubeSize+space,0,0); //row2 col2 cube  -- center cube
	[self drawMiniCubeY:(cubeArray[4]) ];
	glTranslatef(cubeSize+space,0,0); //row2 col3 cube
	[self drawMiniCubeY:(cubeArray[5]) ];
	glTranslatef(-2*(cubeSize+space), -(cubeSize+space),0);  //row3 col1 cube
	[self drawMiniCubeY:(cubeArray[6]) ];
	glTranslatef(cubeSize+space,0,0); //row3 col2 cube
	[self drawMiniCubeY:(cubeArray[7]) ];
	glTranslatef(cubeSize+space,0,0); //row3 col3 cube
	[self drawMiniCubeY:(cubeArray[8]) ];
	glPopMatrix();
}

- (void) drawXSlice:(int) num{  // draw one of the X slices 7,8, or 9
	int cubeArray[9];
    
	if(num==7) {		 //x slice7  1,4,7,10,13,16,19,22,25
		cubeArray[0]= 19;
		cubeArray[1]= 10;
		cubeArray[2]= 1;
		cubeArray[3]= 22;
		cubeArray[4]= 13;
		cubeArray[5]= 4;
		cubeArray[6]= 25;
		cubeArray[7]= 16;
		cubeArray[8]= 7;
	}
	else if(num==8) { //x slice8  2,5,8,11,14,17,20,23,26
		cubeArray[0]= 20;
		cubeArray[1]= 11;
		cubeArray[2]= 2;
		cubeArray[3]= 23;
		cubeArray[4]= 14;
		cubeArray[5]= 5;
		cubeArray[6]= 26;
		cubeArray[7]= 17;
		cubeArray[8]= 8;
	}
	else if(num==9) { //x slice9  3,6,9,12,15,18,21,24,27
		cubeArray[0]= 21;  //21,3,12
		cubeArray[1]= 12;
        cubeArray[2]= 3;
		cubeArray[3]= 24;  //24,6,15
		cubeArray[4]= 15;
		cubeArray[5]= 6;
		cubeArray[6]= 27;  //27,9,18
		cubeArray[7]= 18;
		cubeArray[8]= 9;
	}
	glPushMatrix();
	glTranslatef(-(cubeSize+space), cubeSize+space ,0); //row1 col1 cube
	[self drawMiniCubeX:(cubeArray[0]) ];           // slice num 7 8 or 9
	glTranslatef(cubeSize+space,0,0);  //row1 col2 cube
	[self drawMiniCubeX:(cubeArray[1]) ];
	glTranslatef(cubeSize+space,0,0);  //row1 col3 cube
	[self drawMiniCubeX:(cubeArray[2]) ];
	glTranslatef(-2*(cubeSize+space), -(cubeSize+space),0);  //row2 col1 cube
	[self drawMiniCubeX:(cubeArray[3]) ];
	glTranslatef(cubeSize+space,0,0); //row2 col2 cube  -- center cube
	[self drawMiniCubeX:(cubeArray[4]) ];
	glTranslatef(cubeSize+space,0,0); //row2 col3 cube
	[self drawMiniCubeX:(cubeArray[5]) ];
	glTranslatef(-2*(cubeSize+space), -(cubeSize+space),0);  //row3 col1 cube
	[self drawMiniCubeX:(cubeArray[6]) ];
	glTranslatef(cubeSize+space,0,0); //row3 col2 cube
	[self drawMiniCubeX:(cubeArray[7]) ];
	glTranslatef(cubeSize+space,0,0); //row3 col3 cube
	[self drawMiniCubeX:(cubeArray[8]) ];
	glPopMatrix();
}

- (void) drawMiniCubeZ:(int) num {   //draw cube looking from Z
	//glColor3fv(colors[cubes[num-1].faceColors[0]]);
    
    //draw Front
	[self drawFaceWithVert1:faceVertsZ[0][0] andVert2:faceVertsZ[0][1] andVert3:faceVertsZ[0][2] andVert4:faceVertsZ[0][3] ];
    
    //draw Right
//	glColor3fv(colors[cubes[num-1].faceColors[1]]);
	[self drawFaceWithVert1:faceVertsZ[1][0] andVert2:faceVertsZ[1][1] andVert3:faceVertsZ[1][2] andVert4:faceVertsZ[1][3]];
    
    //draw bottom
//	glColor3fv(colors[cubes[num-1].faceColors[2]]);
   [self drawFaceWithVert1:faceVertsZ[2][0] andVert2:faceVertsZ[2][1] andVert3:faceVertsZ[2][2] andVert4:faceVertsZ[2][3]];
    
    //draw left
//	glColor3fv(colors[cubes[num-1].faceColors[3]]);
   [self drawFaceWithVert1:faceVertsZ[3][0] andVert2:faceVertsZ[3][1] andVert3:faceVertsZ[3][2] andVert4:faceVertsZ[3][3]];
    
    //draw back
//	glColor3fv(colors[cubes[num-1].faceColors[4]]);
    [self drawFaceWithVert1:faceVertsZ[4][0] andVert2:faceVertsZ[4][1] andVert3:faceVertsZ[4][2] andVert4:faceVertsZ[4][3]];
    
    //draw top
//	glColor3fv(colors[cubes[num-1].faceColors[5]]);
   [self drawFaceWithVert1:faceVertsZ[5][0] andVert2:faceVertsZ[5][1] andVert3:faceVertsZ[5][2] andVert4:faceVertsZ[5][3]];
}

- (void) drawMiniCubeY:(int) num{ //draw cube looking from Y
//	glColor3fv(colors[cubes[num-1].faceColors[0]]);
    [self drawFaceWithVert1:faceVertsY[0][0] andVert2:faceVertsY[0][1] andVert3:faceVertsY[0][2] andVert4:faceVertsY[0][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[1]]);
    [self drawFaceWithVert1:faceVertsY[1][0] andVert2:faceVertsY[1][1] andVert3:faceVertsY[1][2] andVert4:faceVertsY[1][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[2]]);
    [self drawFaceWithVert1:faceVertsY[2][0] andVert2:faceVertsY[2][1] andVert3:faceVertsY[2][2] andVert4:faceVertsY[2][3]];
	//glColor3fv(colors[cubes[num-1].faceColors[3]]);
    [self drawFaceWithVert1:faceVertsY[3][0] andVert2:faceVertsY[3][1] andVert3:faceVertsY[3][2] andVert4:faceVertsY[3][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[4]]);
    [self drawFaceWithVert1:faceVertsY[4][0] andVert2:faceVertsY[4][1] andVert3:faceVertsY[4][2] andVert4:faceVertsY[4][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[5]]);
    [self drawFaceWithVert1:faceVertsY[5][0] andVert2:faceVertsY[5][1] andVert3:faceVertsY[5][2] andVert4:faceVertsY[5][3]];
}

- (void) drawMiniCubeX:(int) num{  //draw cube looking from X
//	glColor3fv(colors[cubes[num-1].faceColors[0]]);
    [self drawFaceWithVert1:faceVertsX[0][0] andVert2:faceVertsX[0][1] andVert3:faceVertsX[0][2] andVert4:faceVertsX[0][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[1]]);
    [self drawFaceWithVert1:faceVertsX[1][0] andVert2:faceVertsX[1][1] andVert3:faceVertsX[1][2] andVert4:faceVertsX[1][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[2]]);
    [self drawFaceWithVert1:faceVertsX[2][0] andVert2:faceVertsX[2][1] andVert3:faceVertsX[2][2] andVert4:faceVertsX[2][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[3]]);
    [self drawFaceWithVert1:faceVertsX[3][0] andVert2:faceVertsX[3][1] andVert3:faceVertsX[3][2] andVert4:faceVertsX[3][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[4]]);
    [self drawFaceWithVert1:faceVertsX[4][0] andVert2:faceVertsX[4][1] andVert3:faceVertsX[4][2] andVert4:faceVertsX[4][3]];
//	glColor3fv(colors[cubes[num-1].faceColors[5]]);
    [self drawFaceWithVert1:faceVertsX[5][0] andVert2:faceVertsX[5][1] andVert3:faceVertsX[5][2] andVert4:faceVertsX[5][3]];
}

// draw one of the six sides of one cube
- (void) drawFaceWithVert1:(int) vert1 andVert2:(int) vert2 andVert3:(int) vert3 andVert4:(int) vert4 {
    // glBegin(GL_POLYGON);
	// glVertex3fv(cubeVerts[vert1]);
	// glVertex3fv(cubeVerts[vert2]);
	// glVertex3fv(cubeVerts[vert3]);
	// glVertex3fv(cubeVerts[vert4]);
    // glEnd
    
    //[0] lower left outer z  //[1] upper left outer z //[2] upper right outer z
    //[3] lower right outer z //[4] lower left inner z //[5] upper left inner z
    //[6] upper right inner z //[7] lower right inner z
    
    GLfloat verts[12];
    verts[0] = cubeVerts[vert1][0];
    verts[1] = cubeVerts[vert1][1];
    verts[2] = cubeVerts[vert1][2];
    
    verts[3] = cubeVerts[vert2][0];
    verts[4] = cubeVerts[vert2][1];
    verts[5] = cubeVerts[vert2][2];
    
    
    verts[6] = cubeVerts[vert3][0];
    verts[7] = cubeVerts[vert3][1];
    verts[8] = cubeVerts[vert3][2];
    
    verts[9] = cubeVerts[vert4][0];
    verts[10] = cubeVerts[vert4][1];
    verts[11] = cubeVerts[vert4][2];
    
    glVertexPointer(3, GL_FLOAT, 0, verts);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    
     /*** Need to use triangles now - no more polygons in ES **/
    //glVertexPointer(3, GL_FLOAT, 0, cubeVerts[0]);
    //glEnableClientState(GL_VERTEX_ARRAY);
    //glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
   // glEnableClientState(GL_COLOR_ARRAY);
    //glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	//glEnd();
}

- (void) drawCube:(int) viewportNum  //draw entire cube
{
	glPushMatrix();
	if(lightingEnabled == 0)
		glDisable(GL_LIGHTING);
	else
		glEnable(GL_LIGHTING);
    
    [EAGLContext setCurrentContext:context];
    
    // use +15 and -15  (+5 and -5 is good) to move look at 
    // gluLookAt(eyeX, eyeY, eyeZ, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    // gluLookAt(5, 5, 5, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    gluLookAt(-5, -5, -5, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    /** IMPORTANT set this first**/
    // glOrthof(-1.0f, 1.0f, -1.5f, 1.5f, -1.0f, 1.0f);
    glOrthof(-20.0f, 20.0f, -20.0f, 20.0f, -20.0f, 20.0f);
    glMatrixMode(GL_MODELVIEW);
    // glRotatef(3.0f, 0.0f, 0.0f, 1.0f);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
	glShadeModel(mode);
	glLineWidth(1);  // for line through axis
    
    // uncomment to spaz out and make the drawing flicker 
    // glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    // [context presentRenderbuffer:GL_RENDERBUFFER_OES];

	glLineWidth(1);  //Reset line width
	//slice one
	glTranslatef(0,0,-(cubeSize+space));
	[self drawZSlice:(1) ];
	//2nd slice 
	glTranslatef(0,0,+(cubeSize+space));
	[self drawZSlice:(2) ];
	//3rd slice 
	glTranslatef(0,0,+(cubeSize+space));
	[self drawZSlice:(3) ];

    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    glPopMatrix();
}

- (void) dealloc
{
	// Tear down GL
	if (defaultFramebuffer)
	{
		glDeleteFramebuffersOES(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer)
	{
		glDeleteRenderbuffersOES(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
	
	// Tear down context
	if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	
	[context release];
	context = nil;
	
	[super dealloc];
}


/**** gluLookAt function robbed off Internet to make porting easier ****/
void gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez,
               GLfloat centerx, GLfloat centery, GLfloat centerz,
               GLfloat upx, GLfloat upy, GLfloat upz)
{
    GLfloat m[16];
    GLfloat x[3], y[3], z[3];
    GLfloat mag;
    
    /* Make rotation matrix */
    
    /* Z vector */
    z[0] = eyex - centerx;
    z[1] = eyey - centery;
    z[2] = eyez - centerz;
    mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
    if (mag) {          /* mpichler, 19950515 */
        z[0] /= mag;
        z[1] /= mag;
        z[2] /= mag;
    }
    
    /* Y vector */
    y[0] = upx;
    y[1] = upy;
    y[2] = upz;
    
    /* X vector = Y cross Z */
    x[0] = y[1] * z[2] - y[2] * z[1];
    x[1] = -y[0] * z[2] + y[2] * z[0];
    x[2] = y[0] * z[1] - y[1] * z[0];
    
    /* Recompute Y = Z cross X */
    y[0] = z[1] * x[2] - z[2] * x[1];
    y[1] = -z[0] * x[2] + z[2] * x[0];
    y[2] = z[0] * x[1] - z[1] * x[0];
    
    /* mpichler, 19950515 */
    /* cross product gives area of parallelogram, which is < 1.0 for
     * non-perpendicular unit-length vectors; so normalize x, y here
     */
    
    mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
    if (mag) {
        x[0] /= mag;
        x[1] /= mag;
        x[2] /= mag;
    }
    
    mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
    if (mag) {
        y[0] /= mag;
        y[1] /= mag;
        y[2] /= mag;
    }
    
#define M(row,col)  m[col*4+row]
    M(0, 0) = x[0];
    M(0, 1) = x[1];
    M(0, 2) = x[2];
    M(0, 3) = 0.0;
    M(1, 0) = y[0];
    M(1, 1) = y[1];
    M(1, 2) = y[2];
    M(1, 3) = 0.0;
    M(2, 0) = z[0];
    M(2, 1) = z[1];
    M(2, 2) = z[2];
    M(2, 3) = 0.0;
    M(3, 0) = 0.0;
    M(3, 1) = 0.0;
    M(3, 2) = 0.0;
    M(3, 3) = 1.0;
#undef M
    glMultMatrixf(m);
    
    /* Translate Eye to Origin */
    glTranslatef(-eyex, -eyey, -eyez);
    
}

@end
