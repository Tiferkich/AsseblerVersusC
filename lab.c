#include "image.h"
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "stb_image.h"
#include "stb_image_write.h"



#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
 

int main(int argc, char*argv[]) {
	unsigned char  *imgfrom,*imgto,*imgnew;
	char buf[8];
	FILE * f;
	long jpg = 0x464A1000E0FFD8FF;
	struct timespec t, t1, t2;
    if (argc!=5){
    	fprintf(stderr,"Usage: %s jpg_file c_result asm_result angle\n",argv[0]);
    	return 1;
    }
	if ((f=fopen(argv[1], "r"))==NULL){
		perror(argv[1]);
		return 1;
	}
	
	fread(buf, 1, sizeof(long), f);
	fclose(f);
	if (*(long*)buf!=jpg){
		fprintf(stderr,"%s - not correct signature jpg_file\n",argv[1]);
		return 1;
	}		
	
	


    int angle = atoi(argv[4]); // угол поворота в градусах
	
    int width, height, channels;
	imgfrom = stbi_load(argv[1], &width, &height, &channels, 0);

    if ((imgfrom = stbi_load(argv[1], &width, &height, &channels, 0))== NULL) {
        fprintf(stderr,"Ошибка загрузки изображения %s\n", argv[1]);
        return 1;
    }
    if (angle<0){
    	angle=360+angle%360;
    }
	
    double pi = 3.14159265358979323846;
    double rad = angle * pi / 180.0;
    double cos_angle = cos(rad);
    double sin_angle = sin(rad);

        // Расчёт размеров нового изображения (dst)
    int dst_width = (int)(width * fabs(cos_angle) + height * fabs(sin_angle));
    int dst_height = (int)(height * fabs(cos_angle) + width * fabs(sin_angle));
    dst_width+=width;
    dst_height+=height;
	int x_offset = (dst_width - width) / 2;
    int y_offset = (dst_height - height) / 2;
    imgnew = (unsigned char *)calloc(dst_width * dst_height * channels,1);
    for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                for (int c = 0; c < channels; c++) {
                    imgnew[((y + y_offset) * dst_width + (x + x_offset)) * channels + c] = imgfrom[(y * width + x) * channels + c];
                }
            }
        }


    
	
    imgto = (unsigned char *)calloc(dst_width * dst_height * channels,1);
    if (imgto == NULL) {
        fprintf(stderr,"Ошибка выделения памяти\n");
        stbi_image_free(imgfrom);
        return 1;
    }
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
    work_image_c(imgnew, imgto, dst_width, dst_height, channels, angle);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t2);
	t.tv_sec=t2.tv_sec-t1.tv_sec;
	if ((t.tv_nsec=t2.tv_nsec-t1.tv_nsec)<0){
		t.tv_sec--;
		t.tv_nsec+=1000000000;
	}
	printf("C: %ld.%09ld\n", t.tv_sec, t.tv_nsec);

    if (!stbi_write_jpg(argv[2], dst_width, dst_height, channels, imgto, 100)) {
        fprintf(stderr,"Ошибка сохранения изображения %s\n", argv[2]);
    } else {
        printf("Успешно сохранено изображение: %s\n", argv[2]);
    }
	memset(imgto,0,dst_width*dst_height*channels);
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t1);
    work_image_asm(imgnew, imgto, dst_width, dst_height, channels, angle);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &t2);
	t.tv_sec=t2.tv_sec-t1.tv_sec;
	if ((t.tv_nsec=t2.tv_nsec-t1.tv_nsec)<0){
		t.tv_sec--;
		t.tv_nsec+=1000000000;
	}
	printf("ASM: %ld.%09ld\n", t.tv_sec, t.tv_nsec);

    if (!stbi_write_jpg(argv[3], dst_width, dst_height, channels, imgto, 100)) {
        fprintf(stderr,"Ошибка сохранения изображения %s\n", argv[3]);
    } else {
        printf("Успешно сохранено изображение: %s\n", argv[3]);
    }

    stbi_image_free(imgfrom);
    free(imgto);

    return 0;
}
