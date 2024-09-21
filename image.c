#include "math.h"


void work_image_c(unsigned char *src, unsigned char *dst, int width, int height,int channels,int angle){
	double pi = 3.14159265358979323846264338327950288419716939937510;
 	double rad = angle * pi / 180.0;  
    double cos_angle = (cos(rad));  
    double sin_angle =( sin(rad));  
	
    int cx = width / 2;  
    int cy = height / 2;  
  
    for (int y = 0; y < height; ++y) {  
        for (int x = 0; x < width; ++x) {  
            int newX = round((cos_angle * (x - cx)) - (sin_angle * (y - cy))) + cx;  
            int newY = round((sin_angle * (x - cx)) +( cos_angle * (y - cy))) + cy;  
  
            if (newX >= 0 && newX < width && newY >= 0 && newY < height) {  
                for (int c = 0; c < channels; ++c) {  
                    dst[(y * width + x) * channels + c] = src[(newY * width + newX) * channels + c];  
                }  
            } else {  
                for (int c = 0; c < channels; ++c) {  
                    dst[(y * width + x) * channels + c] = 0; // заполняем пустое пространство черным цветом  
                }  
            }  
        }  
    }  
}


