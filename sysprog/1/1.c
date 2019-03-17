#include <stdio.h>  // fseek
#include <stdlib.h> // malloc, realloc, atoi
#include <string.h> // strlen


int pivot(int *p, int s, int e)
{
    return p[ s + ( (e - s) >> 1 ) ];
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
        
        array->cap = DEFAULT_CAPACITY;
        array->len = 0;
    }

    if ( array->len == array->cap )
    {
        int *tmp_m = realloc( array->m, ( array->cap + DEFAULT_CAPACITY ) * sizeof( int ) );
        if ( tmp_m == NULL ) return -1;

        array->m = tmp_m;
        array->cap += DEFAULT_CAPACITY;
    }

    array->m[array->len] = x;
    array->len += 1;

    return 0;
}


struct array_len *read_file(char *filename)
{    
    char *mode, *num_buf = NULL;
    int num, c, pos = 0;
    struct array_len *array = NULL;
    const int MAX_NUM_LEN = 21;

    mode = "r";
    FILE *file = fopen( filename, mode );
    if ( file == NULL ) return NULL;

    array = malloc( sizeof( struct array_len ) );
    memset(array, 0, sizeof( struct array_len ) );

    num_buf = malloc( MAX_NUM_LEN );

    while ( 1 )
    {
        c = fgetc( file );

        if (c == ' ' || c == EOF)
        {
            if (pos != 0)
            {
                num_buf[ pos ] = '\0';
                num = atoi(num_buf);

                if ( append_to_array( array, num ) != 0 )
                {
                    fclose( file );
                    free( num_buf );
                    return NULL;
                }

                pos = 0;
            }

            if (c == EOF) break;
        }
        else
        {
            if ( pos >= MAX_NUM_LEN )
            {
                fclose( file );
                free( num_buf );
                return NULL;
            }

            num_buf[ pos ] = (char) c;
            pos++;
        }
    }

    fclose( file );
    free( num_buf );
    return array;
}


int write_to_file(struct array_len *array, char *filename)
{
    if ( array == NULL ) return -1;

    if ( filename == NULL ) return -1;

    if ( array->len < 1 ) return -1;

    int i;
    char *mode = "w";

    FILE *file = fopen( filename, mode );
    if ( file == NULL ) return -1;

    for ( i = 0; i < array->len - 1; i++ )
    {
        fprintf( file, "%d ", array->m[ i ] );
    }
    fprintf( file, "%d", array->m[ array->len - 1 ] );

    fclose( file );
    return 0;
}


int main(int argc, char *argv[])
{    
    if ( argc != 2 ) return 1;

    int i;

    struct array_len *m = NULL;
    
    if ( ( m = read_file( argv[1] ) ) == NULL ) return 1;

    quicksort( m->m, 0, m->len - 1 );

    write_to_file(m, argv[1]);

    free( m->m );
    free( m );
    return 0;
}