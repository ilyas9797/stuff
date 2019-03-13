#include <stdio.h>  // 
#include <stdlib.h> // malloc, realloc, atoi
#include <string.h> // strlen


int pivot(int *p, int s, int e)
{
    return p[s];
}


void quicksort(int *p, int s, int e)
{
    int n, piv, i, j, tmp;

    n = e - s + 1;

    piv = pivot(p, s, e);
    i = s;
    j = e;    
    
    do {
        while (p[i] < piv) i++;
        while (p[j] > piv) j--;

        if (i <= j)
        {
            tmp  = p[i];
            p[i] = p[j];
            p[j] = tmp;

            i++;
            j--;
        }        
    } while (i <= j);

    if (j > s) quicksort(p, s, j);
    if (i < e) quicksort(p, i, e);

    // int m[] = {3,2,1,4,5,4,6,9,6,2,5,4,4,0,7,4,3,7,3,1,7,4,2,7,0,9,8,4,1,3,4,5,6,7,8,7,5};

    // int n = 15;

    // quicksort(m, 0, n-1);

    // for (int i = 0; i < n; i++) printf("%d ", m[i]);
}

#define DEFAULT_CAPACITY 1000

struct array_len
{
    int *m;
    int len;
    int cap; 
};


int append_to_array(struct array_len *array, int x)
{
    if ( array == NULL ) return -1;

    if ( array->m == NULL )
    {
        array->m = malloc( DEFAULT_CAPACITY * sizeof( int ) );        
        if ( array->m == NULL ) return -1;
        
        memset( array->m, 0, DEFAULT_CAPACITY * sizeof( int ) );
        array->cap = DEFAULT_CAPACITY;
        array->len = 0;
    }

    if ( array->len == array->cap )
    {
        int *tmp_m = realloc( array->m, array->cap + DEFAULT_CAPACITY );
        if ( tmp_m == NULL ) return -1;

        free( array->m );
        array->m = tmp_m;
        array->cap += DEFAULT_CAPACITY;
    }

    array->m[array->len] = x;
    array->len += 1;

    return 0;
}


int update_array(struct array_len *array, char *buf)
{
    if ( array == NULL ) return -1;

    if ( buf == NULL ) return -1;
    
    int buf_len = strlen( buf );

    if ( buf_len == 0 ) return -1;

    int i, j = 0;
    char s;
    char *s_num;
    int num, s_num_len;

    if ( array->m == NULL )
    {
        array->m = malloc( DEFAULT_CAPACITY * sizeof( int ) );        
        if ( array->m == NULL ) return -1;
        
        memset(array->m, 0, DEFAULT_CAPACITY * sizeof( int ) );
        array->cap = DEFAULT_CAPACITY;
        array->len = 0;
    }

    while ( j <= buf_len )
    {
        if ( buf[j] == ' ' && i != j )
        {
            s_num_len = j - i;
            s_num = malloc( s_num_len + 1 );
            memcpy( s_num, buf + i, s_num_len );
            s_num[s_num_len] = '\0';

            num = atoi(s_num);

            if ( append_to_array( array, num ) != 0 )
            {
                free( s_num );
                return -1;
            }

            free( s_num );

            j++;
            i = j;
        }

        j++;
    }

    //

    return 0;
}


struct array_len *read_file(char *filename)
{    
    char *mode, *rbuf;
    int count;
    struct array_len *array;
    const int MAX_SYMBOLS_READ = 10000;

    mode = "r";
    FILE *file = fopen( filename, mode );
    if ( file == NULL ) return NULL;

    rbuf = malloc( ( MAX_SYMBOLS_READ + 1 ) * sizeof( char ) );
    if ( rbuf == NULL )
    {
        fclose( file );
        return NULL;
    }

    array = malloc( sizeof( struct array_len ) );
    memset(array, 0, sizeof( struct array_len ) );

    while ( fgets( rbuf, MAX_SYMBOLS_READ + 1, file ) )
    {
        
    }


    fclose( file );
    free(rbuf);
    return array;
}


int main(int argc, char *argv[])
{    
    if ( argc != 2 ) return 1;

    struct array_len *m = read_file( argv[1] );



    return 0;
}