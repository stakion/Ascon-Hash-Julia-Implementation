######################################################################################################################################################
# Variables globales para permitir depurar el código.
######################################################################################################################################################
debug_variables = true
debugpermutation = false
debug = true
######################################################################################################################################################


######################################################################################################################################################
# Función para considerar una cantidad n de bytes inicializada en cero.
######################################################################################################################################################
function zero_bytes(n)
    return zeros(UInt8, n)
end
######################################################################################################################################################


######################################################################################################################################################
# Función para convertir a bytes un arreglo.
######################################################################################################################################################
function to_bytes(l)
    # Convertir cada elemento de l a UInt8 y recolectar en un Vector{UInt8}
    return UInt8[UInt8(e) for e in l]
end
######################################################################################################################################################


######################################################################################################################################################
# Función para convertir un arreglo de bytes a número entero.
## Función para considerar los valores de 64 bits construidos a partir de 8 elementos de 1 byte cada uno recorridos los lugares correspondientes.
######################################################################################################################################################
function bytes_to_int(b_bytes::Vector{UInt8})
    return  (UInt64(b_bytes[1]) << 56) | (UInt64(b_bytes[2]) << 48) | (UInt64(b_bytes[3]) << 40) | (UInt64(b_bytes[4]) << 32) |
            (UInt64(b_bytes[5]) << 24) | (UInt64(b_bytes[6]) << 16) | (UInt64(b_bytes[7]) << 8) | UInt64(b_bytes[8] )
end
######################################################################################################################################################


######################################################################################################################################################
# Función para realizar la conversión de entero a bytes.
######################################################################################################################################################
function int_to_bytes(integer::Integer, nbytes::Integer)
    bytes = UInt8[]  # Crear un arreglo vacío de UInt8
    for i in 0:(nbytes - 1)
        byte = UInt8((integer >> (i * 8)) % 256)        # Desplazar el entero a la derecha y tomar el módulo de 256 para obtener el byte actual
        bytes = [byte; bytes]                           # Prepend el byte al arreglo, porque Julia añade elementos al final
    end
    return bytes
end
######################################################################################################################################################


######################################################################################################################################################
# Función para convertir el vector de bytes a un estado de la palabra S con 5 cadenas de 64 bits u 8 bytes cada una.
######################################################################################################################################################
function vector_byte_to_state(a_bytes)
    # El arreglo considerado como parámetro debe de recuperar 40 bytes, 16 bytes por palabra de 64 bits ( x_n ).
    ## Arreglos auxiliares de 8 elementos de 1 byte cada uno.
    ### Valores enteros de 64 bits auxiliares considerando cada 8 elementos del arreglo auxiliar.
    aux_x0 = a_bytes[1:8];          aux_xx0 = bytes_to_int(aux_x0)
    aux_x1 = a_bytes[9:16];         aux_xx1 = bytes_to_int(aux_x1)
    aux_x2 = a_bytes[17:24];        aux_xx2 = bytes_to_int(aux_x2)
    aux_x3 = a_bytes[25:32];        aux_xx3 = bytes_to_int(aux_x3)
    aux_x4 = a_bytes[33:40];        aux_xx4 = bytes_to_int(aux_x4)

    return [ aux_xx0 , aux_xx1 , aux_xx2 , aux_xx3 , aux_xx4 ]
end
######################################################################################################################################################


######################################################################################################################################################
# Función para normalizar la cantidad de ceros en cada uno de los elementos del arreglo considerando n/4 bits.
## Solo útil para la impresión de la cadena de hexadecimales no normalizados.
######################################################################################################################################################
function NS_HEX(SS, n::Int)
    a_aux_3 = []
    for i in 1:length(SS)
        aux_1 = string(SS[i])
        aux_2 = lpad(aux_1, n, '0')
        a_aux_3 = push!( a_aux_3 , aux_2)
    end
    return a_aux_3
end
######################################################################################################################################################



######################################################################################################################################################
# Función para considerar la rotación hacia la derecha tomando en cuenta las palabras de 64 bits, utilizada en la capa lineal de la permutación Ascon.
######################################################################################################################################################
function RR_64(x::UInt64, n::Int)
    return (x >> n) | ( x << (64 - n) )
end
######################################################################################################################################################


######################################################################################################################################################
# Función para concatenar los elementos de un arreglo en una cadena de texto.
######################################################################################################################################################
function Concatenate_Array(aux_array_00)
    aux_s = ""
    for i in range( 1 , length(aux_array_00) )
        aux_s = aux_s * string( aux_array_00[i] , base=16 )
    end
    return aux_s
end
######################################################################################################################################################


######################################################################################################################################################
# Funnción para imprimir el estado de S con un determinado mensaje.
######################################################################################################################################################
function Print_state_S( aux_S , aux_message )
    println( aux_message )
    println( string( aux_S[1] , base=16 ) )
    println( string( aux_S[2] , base=16 ) )
    println( string( aux_S[3] , base=16 ) )
    println( string( aux_S[4] , base=16 ) )
    println( string( aux_S[5] , base=16 ) )
end
######################################################################################################################################################


######################################################################################################################################################
# Función para calcular la salida en base a caja de sustitucion, en este caso se hace uso de la expresión lógica.
######################################################################################################################################################
function Ascon_Sbox_00( S )
    # Operaciones xor realizadas sobre cada una de las constantes correspondientes.
    S[1] = xor( S[1] , S[5] )
    S[5] = xor( S[5] , S[4] )
    S[3] = xor( S[3] , S[2] ) 

    # Cadena de 1's completos convertida a entero de 64 bits.
    c_aux_00_FF = parse(UInt64, "FFFFFFFFFFFFFFFF", base=16)
    
    # Arreglo auxiliar considerado para realizar xor más tarde.
    T = [ xor( UInt64( S[i] ) , c_aux_00_FF ) & S[ mod1( i+1 , 5 ) ] for i in 1:5 ]

    # Se realiza xor sobre cada uno de los elementos correspondientes del arreglo.
    for i in 1:5
        S[i] = xor( S[i] , T[ mod1( i+1 , 5 ) ] ) 
    end

    # Operaciones xor realizadas sobre cada una de las constantes correspondientes.
    S[2] = xor( S[2] , S[1] )
    S[1] = xor( S[1] , S[5] )
    S[4] = xor( S[4] , S[3] )
    S[3] = xor( S[3] , c_aux_00_FF )

    return S
end
######################################################################################################################################################


######################################################################################################################################################
# Función para calcular la salida en base a caja de sustitucion, en este caso se hace uso de la expresión lógica.
# Version descompuesta en las operaciones más simples.
######################################################################################################################################################
function Ascon_Sbox_02( S )
    # Operaciones xor realizadas sobre cada una de las constantes correspondientes.
    S[1] = xor( S[1] , S[5] )
    S[5] = xor( S[5] , S[4] )
    S[3] = xor( S[3] , S[2] ) 

    # Cadena de 1's completos convertida a entero de 64 bits.
    c_aux_00_FF = parse(UInt64, "FFFFFFFFFFFFFFFF", base=16)
    
    # Arreglo auxiliar considerado para realizar xor más tarde.
    T = [   xor( UInt64( S[1] ) , c_aux_00_FF ) & S[2] ,
            xor( UInt64( S[2] ) , c_aux_00_FF ) & S[3] , 
            xor( UInt64( S[3] ) , c_aux_00_FF ) & S[4] ,
            xor( UInt64( S[4] ) , c_aux_00_FF ) & S[5] , 
            xor( UInt64( S[5] ) , c_aux_00_FF ) & S[1] ]

    # Se realiza xor sobre cada uno de los elementos correspondientes del arreglo.
    S[1] = xor( S[1] , T[2] ) 
    S[2] = xor( S[2] , T[3] ) 
    S[3] = xor( S[3] , T[4] ) 
    S[4] = xor( S[4] , T[5] ) 
    S[5] = xor( S[5] , T[1] ) 

    # Operaciones xor realizadas sobre cada una de las constantes correspondientes.
    S[2] = xor( S[2] , S[1] )
    S[1] = xor( S[1] , S[5] )
    S[4] = xor( S[4] , S[3] )
    S[3] = xor( S[3] , c_aux_00_FF )
    return S
end
######################################################################################################################################################


######################################################################################################################################################
# Función para calcular la salida en base a caja de sustitucion, en este caso se hace uso de la tabla de valores.
######################################################################################################################################################
function Ascon_S_box_01( b0, b1, b2, b3, b4 )
    # Consideración de valor hexadecimal de entrada.
    cc = (b0 << 4) | (b1 << 3) | (b2 << 2) | (b3 << 1) | b4         ## Tomar en cuenta x4 como el bit menos significativo.
    cc = cc & 0x1F                                                  # Forzar que la entrada es de 5 bits

    return  Int( cc == 0x00 )*( 0x04 ) + 
            Int( cc == 0x01 )*( 0x0b ) + 
            Int( cc == 0x02 )*( 0x1f ) + 
            Int( cc == 0x03 )*( 0x14 ) + 
            Int( cc == 0x04 )*( 0x1a ) + 
            Int( cc == 0x05 )*( 0x15 ) + 
            Int( cc == 0x06 )*( 0x09 ) + 
            Int( cc == 0x07 )*( 0x02 ) + 
            Int( cc == 0x08 )*( 0x1b ) + 
            Int( cc == 0x09 )*( 0x05 ) + 
            Int( cc == 0x0a )*( 0x08 ) + 
            Int( cc == 0x0b )*( 0x12 ) + 
            Int( cc == 0x0c )*( 0x1d ) + 
            Int( cc == 0x0d )*( 0x03 ) + 
            Int( cc == 0x0e )*( 0x06 ) + 
            Int( cc == 0x0f )*( 0x1c ) + 
            Int( cc == 0x10 )*( 0x1e ) + 
            Int( cc == 0x11 )*( 0x13 ) + 
            Int( cc == 0x12 )*( 0x07 ) + 
            Int( cc == 0x13 )*( 0x0e ) + 
            Int( cc == 0x14 )*( 0x00 ) + 
            Int( cc == 0x15 )*( 0x0d ) + 
            Int( cc == 0x16 )*( 0x11 ) + 
            Int( cc == 0x17 )*( 0x18 ) + 
            Int( cc == 0x18 )*( 0x10 ) + 
            Int( cc == 0x19 )*( 0x0c ) + 
            Int( cc == 0x1a )*( 0x01 ) + 
            Int( cc == 0x1b )*( 0x19 ) + 
            Int( cc == 0x1c )*( 0x16 ) + 
            Int( cc == 0x1d )*( 0x0a ) + 
            Int( cc == 0x1e )*( 0x0f ) + 
            Int( cc == 0x1f )*( 0x17 )
end
######################################################################################################################################################


######################################################################################################################################################
# Función para calcular la salida en base a caja de sustitucion, en este caso se hace uso de la tabla de valores.
######################################################################################################################################################
function Ascon_Linear_Layer( S )
    s_aux_01 = xor( RR_64( S[1] , 19 ) , RR_64( S[1] , 28 ) )
    s_aux_02 = xor( RR_64( S[2] , 61 ) , RR_64( S[2] , 39 ) )
    s_aux_03 = xor( RR_64( S[3] ,  1 ) , RR_64( S[3] ,  6 ) )
    s_aux_04 = xor( RR_64( S[4] , 10 ) , RR_64( S[4] , 17 ) )
    s_aux_05 = xor( RR_64( S[5] ,  7 ) , RR_64( S[5] , 41 ) )

    # Zona de impresión de los valores obtenidos despues de realizar el xor correspondiente.
    #println("Valor asociado a la constante xor palabra 1: " * string(s_aux_01, base=16) )
    # println("Valor asociado a la constante xor palabra 2: " * string(s_aux_02, base=16) ) 
    # println("Valor asociado a la constante xor palabra 3: " * string(s_aux_03, base=16) ) 
    # println("Valor asociado a la constante xor palabra 4: " * string(s_aux_04, base=16) ) 
    # println("Valor asociado a la constante xor palabra 5: " * string(s_aux_05, base=16) )

    ## Validar cada una de las constantes R_aux:
    # println("R_aux_01: " * string(  RR_64( S[1] , 19 ) , base=16) )
    # println("R_aux_02: " * string(  RR_64( S[1] , 28 ) , base=16) )
    # println("R_aux_03: " * string(  RR_64( S[2] , 61 ) , base=16) )
    # println("R_aux_04: " * string(  RR_64( S[2] , 39 ) , base=16) )
    # println("R_aux_05: " * string(  RR_64( S[3] ,  1 ) , base=16) )
    # println("R_aux_06: " * string(  RR_64( S[3] ,  6 ) , base=16) )
    # println("R_aux_07: " * string(  RR_64( S[4] , 10 ) , base=16) )
    # println("R_aux_08: " * string(  RR_64( S[4] , 17 ) , base=16) )
    # println("R_aux_09: " * string(  RR_64( S[5] ,  7 ) , base=16) )
    # println("R_aux_10: " * string(  RR_64( S[5] , 41 ) , base=16) )

    S[1] = xor( S[1] , s_aux_01 ) 
    S[2] = xor( S[2] , s_aux_02 ) 
    S[3] = xor( S[3] , s_aux_03 )
    S[4] = xor( S[4] , s_aux_04 )
    S[5] = xor( S[5] , s_aux_05 )
    return S
end
######################################################################################################################################################


######################################################################################################################################################
# Permutación Ascon considerando las funciones previamente definidas.
######################################################################################################################################################
function Ascon_Permutation(S, rounds=1)
    # Imprimir S si debugpermutation es verdadero
    #if( debugpermutation == true)
    #    Print_state_S( S , "PI: Permutation entrada: " )
    #end

    for r in range(12-rounds, 12-1)
        #########################################################
        # Parte correspondiente a pc, unicamente afectando a x2 - S[3]
        valor_r = r
        aux_aux_01 =  UInt64(0xf0 - r*0x10 + r*0x1) 
        aux_aux_02 = xor( S[3] , UInt64(0xf0 - r*0x10 + r*0x1) )
        S[3] = xor( S[3] , UInt64(0xf0 - r*0x10 + r*0x1) )                # Considerando la constante r que se utiliza en el xor correspondiente.

        if(debugpermutation)
            println( "PC: Adición de la constante de redondeo: " * string(S) )
            # println( "Valor asociado a la constante para la operación xor: " * string( aux_aux_01 ) )
            # println( "Valor asociado a la operación xor realizada: " * string( aux_aux_02 ) )
            # println( "Valor de r: " * string( valor_r ) )
        end
        #########################################################

        #########################################################
        # Parte no lineal correspondiente a la caja de sustitución.
        S = Ascon_Sbox_02( S )

        if(debugpermutation)
            println( "PS: Capa de Sustitución de la permutación Ascon: " * string(S) )
        end
        #########################################################

        #########################################################
        # Parte lineal de la permutación Ascon.
        S = Ascon_Linear_Layer( S )

        if(debugpermutation)
            println( "PL: Capa lineal de la permutación Ascon: " * string(S) )
        end
    end
    return S
end
######################################################################################################################################################


######################################################################################################################################################
# Pruebas realizadas con python y Julia, considerar ejecución dentro de Julia de la implementación en python.
######################################################################################################################################################
# SS = [UInt64(4966426809220072797), UInt64(2025992124789964025), UInt64(7252845576982058001), UInt64(4610287821674641502), UInt64(7004829708873714794) ]
SS = [UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0) ]
AUX_SI = Ascon_Permutation(SS, 12)


# for i in range(1, 12)
#    SS = [UInt64(0), UInt64(0), UInt64(0), UInt64(0), UInt64(0) ]
#    AUX_SI = Ascon_Permutation(SS, rounds=i)
#    println("--------------------------------------------------------------------------------------------------")
#    println("Permutación Ascon realizada : " * string(i) )
#    println("Palabra de 320 bits despues de i veces aplicada la permutación ascon : " * string( AUX_SI ) )
#    println("--------------------------------------------------------------------------------------------------")
#    println("")
#end
######################################################################################################################################################


######################################################################################################################################################
# Función Hash con todos los pasos internos.
######################################################################################################################################################
function Ascon_HASH( message, variant="Ascon-Hash", hashlength=32)
    # Declaración de variables de redondeo iniciales.
    a = 12
    b = variant in ["Ascon-Hasha", "Ascon-Xofa"] ? 8 : 12
    rate = 8

    # Considerar la implementación donde a = 12, b = 12 para hardware VHDL
    
    # Proceso de Inicialización:
    value = variant in ["Ascon-Hash", "Ascon-Hasha"] ? 256 : 0
    tagspec = int_to_bytes(value, 4)

    if(debug_variables)
        println("a : " * string( a )  )
        println("b : " * string( b )  )
        println("rate : " * string( rate )  )
        println("value : " * string( value )  )
        println("tagspec : " * string( tagspec )  )
        println("zero_bytes : " * string( zero_bytes(32) )  )
        println("to_bytes : " * string( to_bytes([0, rate*8+0, a+0, a-b+0]) )  )
        println("Concat : " * string( vcat(to_bytes([0, rate*8, a, a-b]), tagspec, zero_bytes(32) ) ) )
    end

    # El vector de entrada debe de tener 40 bytes de tamaño, o ser de 40 elementos de 1 byte cada uno para representar correctamente las 5 palabras de 64 bits
    S = vector_byte_to_state( vcat(to_bytes([0, rate*8, a, a-b]), tagspec, zero_bytes(32) ) ) # 4 , 4 , 32 

    if(debug)
        Print_state_S( S , "VALOR CERO : " )
    end

    # Primera permutación ASCON realizada a veces
    S = Ascon_Permutation(S, a)

    if(debug)
        Print_state_S( S , "INICIALIZACIÓN : " )
    end


    # Message Processing (Absorbing)
    m_bytes = Vector{UInt8}(message)                                # Mensaje convertido a valor de bytes.
    mz_bytes = zero_bytes(rate - (length(message) % rate) - 1)      # Cantidad de ceros a considerar para rellenar los bytes correspondientes.
    m_padded = vcat( m_bytes , to_bytes([0x80]) , mz_bytes )        # Arreglo auxiliar para concatenar toda la información relacionada al mensaje en bytes.

    if(debug_variables)
        println("m_bytes : " * string( m_bytes )  )
        println("mz_bytes : " * string( mz_bytes )  )
        println("m_padded : " * string( m_padded )  )
    end

    # Si se cumple que la cantidad de iteraciones sera mayor al tamaño del bloque dado por la variable rate.
    if( length(m_padded) - rate + 1  > rate )
        ## Considerar los primeros s-1 bloques
        println("Se consideraran el ciclo con b permutaciones ascon. " )
        
        for block in range( start = 1 , stop = length(m_padded) - rate + 1, step = rate )
            S[1] = xor( S[1] , bytes_to_int( m_padded[block:block+7] ) )
            S = Ascon_Permutation(S, b)
        end
    end
    
    # Último bloque, si no se considera la expresión dentro del if se pasa directo a esta expresión.
    block = UInt64( length(m_padded) - rate + 1)
    S[1] = xor( S[1] , bytes_to_int( m_padded[block:block+7] ) )  # rate=8
    
    if(debug)
        Print_state_S( S , "MENSAJE PROCESADO: " )
    end


    # Finalization (Squeezing)
    H = ""
    S = Ascon_Permutation(S, a)

    if(debug)
        Print_state_S( S , "PRIMERA PARTE FINALIZACIÓN: " )
    end

    while length(H) < hashlength*2-14
        
        aux_bytes_00 = int_to_bytes(S[1], rate)

        for i in range( 1 , length(aux_bytes_00) )
            # Considerando el caso de que solo se tenga un único byte, se concatena el cero adicional faltante.
            if( length(string( aux_bytes_00[i] , base=16 ) ) == 1 )
                H = H * "0" * string( aux_bytes_00[i] , base=16 )

            # Caso contrario se concatena de forma normal.
            else
                H = H * string( aux_bytes_00[i] , base=16 )
            end

        end

        S = Ascon_Permutation(S, b)
    end

    if(debug)
        Print_state_S( S , "FINALIZACIÓN : " )
        println("-------------------------------------" )
        println(" HASH FINAL: " *  string( H ) )
        println(" BYTES MENSAJE: " * string( Concatenate_Array( m_bytes ) ))
        println("")
    end

    return H
end

Ascon_HASH( "HOLAA" )

Ascon_HASH( "HOLAe" )

Ascon_HASH( "HOLAI" )

Ascon_HASH( "HOLAo" )


# INICIALIZACIÓN:
# 313c0274c1b642c5
# 36176103d9deed44
# ee42ed04f3c9d8af
# b7d50a0991ea5ada
# faec8d8caa963039
# ee9398aadb67f03d 8bb21831c60f1002 b48a92db98d5da62 43189921b8f8e3e8 348fa5c9d525e140

# Considerar datos de prueba para validar implementación
# Cosiderar la implementación propia.

# Validar para más cadenas de texto.