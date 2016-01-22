PROGRAM main
USE master
IMPLICIT NONE
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ INITIALIZE MPI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
CALL MPI_INIT(ierr)
CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
CALL MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, ierr)

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ SET VARIABLES  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

nstop = 20000
nx = 100 + 2
ny = 100 + 2

xmin = 0.0
xmax = 1.0
ymin = 0.0
ymax = 1.0

dx = (xmax-xmin)/(nx-1)
dy = (ymax-ymin)/(ny-1)

f = dx*dy
one_over_hsq = 1.0 / (dx*dy)

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ ALLOCATE AND INITIALIZE GLOBAL ARRAY ~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
ALLOCATE(u_global(nx,ny))

DO j = 1, ny
    DO i = 1,nx
        u_global(i,j) = 0.0
    ENDDO
ENDDO

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ SET MPI TOPO VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
ndims   = 2
dims(1) = 2
dims(2) = 2
periods(1) = .FALSE.
periods(2) = .FALSE.
reorder    = .FALSE.

CALL MPI_CART_CREATE(MPI_COMM_WORLD, ndims, dims, periods, reorder, &
                     comm_cart, ierr)
CALL MPI_COMM_RANK(comm_cart, rank_cart, ierr)
CALL MPI_CART_COORDS(comm_cart, rank_cart, ndims, coords_cart, ierr)

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ FIND LOCAL DIM/VARS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
lnx = (nx-2)/2 + 2 
lny = (ny-2)/2 + 2

i_cart = coords_cart(1)
j_cart = coords_cart(2)

limin = 1
limax = lnx

ljmin = 1
ljmax = lny

gimin = 2 + i_cart * (lnx-2)
gimax = gimin + (lnx-3) 

gjmin = 2 + j_cart * (lny-2)
gjmax = gjmin + (lny-3)

!PRINT*, gimin, gimax, gjmin, gjmax

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ FIND IMEDIATE NEIGHBOURS AND GLOBAL BOUNDARIES ~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

CALL MPI_CART_SHIFT(comm_cart,0,1,nghbr_top,nghbr_bottom,ierr)
CALL MPI_CART_SHIFT(comm_cart,1,1,nghbr_left,nghbr_right,ierr)

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ ALLOCATE AND INITIALIZE LOCAL ARRAY ~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

ALLOCATE(u(lnx,lny))
DO j = 1,lny
    DO i = 1,lnx
        u(i,j) = 0.0
    ENDDO
ENDDO

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ ALLOCATE GHOST ARRAYS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

ALLOCATE(ghst_top(lny-2))
ALLOCATE(ghst_bottom(lny-2))
ALLOCATE(ghst_left(lnx-2))
ALLOCATE(ghst_right(lnx-2))

!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~ ALLOCATE AND INITIALIZE LOCAL ARRAY ~~~~~~~~~~~~~~~~~~~~~~~!
!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

resi = 10000.0
DO WHILE (resi.GT.0.01.AND.it.LT.nstop)
    CALL rb_gs()
    CALL comm()
    CALL residual
    !IF (rank.eq.0.and.mod(it,100).eq.0) THEN
    !    PRINT*, resi
    !ENDIF
ENDDO 

DO j = 2,lny-1
    DO i = 2,lnx-1
        u_global(gimin+(i-2),gjmin+(j-2)) = u(i,j)
    ENDDO
ENDDO

CALL write2txt()


CALL MPI_FINALIZE(ierr)
END PROGRAM main
