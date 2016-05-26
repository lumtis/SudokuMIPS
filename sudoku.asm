.data

#############################################################
# Variables globals



# Chaines de caracteres
string_error:		.asciiz	"Erreur : pas de grille\n"

# Space représente des tableaux de byte consecutifs
# Tableau du sudoku d'origine
original:	.space	81
# Tableau determinant l'etat actuel du sudoku
grille:		.space 	81
# Tableau utilisé pour ranger toute les cases d'un carre ou d'une colonne dans une seule ligne
ligne: 		.space	9

.text

#############################################################
# Fonctions pre-implementees

# Effectue un retour a la ligne a l'ecran
# Registres utilises : $v0, $a0
newLine:
	li	$v0, 11
	li	$a0, 10
	syscall
	jr $ra

# Ouverture d'un fichier. 
# $a0 nom du fichier, 
# $a1 le flag d'ouverture (0 lecture, 1 ecriture)
# Registres utilises : $v0, $a2
openfile: 
	li   	$v0, 13       # system call for open file
	li   	$a2, 0
	syscall               # open a file (file descriptor returned in $v0)
	jr 	$ra

# Ferme le fichier
# $a0 le descripteur de fichier qui est ouvert.
# Registres utilises : $v0
closeFile:
	li	$v0, 16 	#Syscall value for closefile.
	syscall
	jr 	$ra

# Lit une ligne du fichier et la mets dans le tableau grille
# $a0 le descripteur de fichier qui est ouvert.
# Registres utilises : $v0, $a1, $a2
extractionValue:
	li	$v0, 14
	la 	$a1, original 
	li 	$a2, 81
	syscall
	jr 	$ra


# Affiche la grille originale.
# Registres utilises : $v0, $a0, $t[0-2]
printArrayOriginal:  
	add $sp, $sp, -4	# Sauvegarde de la reference du dernier jump
	sw 	$ra, 0($sp)
	
	la	$t0, original			
	li	$t1, 0
	boucle_printArrayOriginal:
		bge $t1, 81, end_printArrayOriginal
			add $t2, $t0, $t1
			lb	$a0, ($t2)
			li	$v0, 1
			syscall
			add	$t1, $t1, 1
		j boucle_printArrayOriginal
	end_printArrayOriginal:
	
	jal newLine
	
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

# Affiche la grille.
# Registres utilises : $v0, $a0, $t[0-2]
printArray:  
	add $sp, $sp, -4
	sw 	$ra, 0($sp)
	add $sp, $sp, -4
	sw 	$v0, 0($sp)
	jal save_reg
	
	la	$t0, grille			
	li	$t1, 0
	boucle_printArray:
		bge $t1, 81, end_printArray 		# Si $t1 est plus grand ou egal a 81 alors branchement a end_printArray
			add $t2, $t0, $t1				# $t0 + $t1 -> $t2 ($t0 l'adresse du tableau et $t1 la position dans le tableau)
			lb	$a0, ($t2)					# load byte at $t2(adress) in $a0
			li	$v0, 1						# code pour l'affichage d'un entier
			syscall
			add	$t1, $t1, 1					# $t1 += 1;
		j boucle_printArray
	end_printArray:
	
	jal newLine
	
	jal load_reg
	lw 	$v0, 0($sp)
	add $sp, $sp, 4
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra


# Change array from ascii to integer
# Registres utilises : $t[0-3]
changeArrayAsciiCode:  
	add $sp, $sp, -4
	sw 	$ra, 0($sp)
	la	$t3, original
	li	$t0, 0
	boucle_changeArrayAsciiCode:
		bge 	$t0, 81, end_changeArrayAsciiCode
			add	$t1, $t3, $t0
			lb	$t2, ($t1)
			sub $t2, $t2, 48
			sb	$t2, ($t1)
			add	$t0, $t0, 1
		j boucle_changeArrayAsciiCode
	end_changeArrayAsciiCode:
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

# Fait le modulo (a mod b)
# $a0 represente le nombre a (doit etre positif)
# $a1 represente le nombre b (doit etre positif)
# Resultat dans : $v0
# Registres utilises : $a0
modulo: 
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	sub $sp, $sp, 4
	sw 	$a0, 0($sp)
	
	boucle_modulo:
		blt	$a0, $a1, end_modulo
		sub	$a0, $a0, $a1
		j boucle_modulo
	end_modulo:
	move 	$v0, $a0
	
	lw 	$a0, 0($sp)
	add $sp, $sp, 4
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra


#############################################################
# Fonctions personalisees


# Sauvegarde les registres le plus importants
save_reg:
	sub $sp, $sp, 4
	sw 	$a0, 0($sp)
	sub $sp, $sp, 4
	sw 	$a1, 0($sp)
	sub $sp, $sp, 4
	sw 	$t0, 0($sp)
	sub $sp, $sp, 4
	sw 	$t1, 0($sp)
	sub $sp, $sp, 4
	sw 	$t2, 0($sp)
	jr $ra


# Charge les registres les plus importants
load_reg:
	lw 	$t2, 0($sp)
	add $sp, $sp, 4
	lw 	$t1, 0($sp)
	add $sp, $sp, 4
	lw 	$t0, 0($sp)
	add $sp, $sp, 4
	lw 	$a1, 0($sp)
	add $sp, $sp, 4
	lw 	$a0, 0($sp)
	add $sp, $sp, 4
	jr $ra



# Position = i+9*n
# Obtient l'emplacement absolue d'une ligne
# $a0 represente le numero de la ligne (compris en 0 et 8)
# $a1 represente l'offset dans la ligne (compris en 0 et 8)
# Resultat dans : $v0, position absolue de la ligne
# Registres utilises : $v0
ligne_to_case:
	mul $v0, $a0, 9
	add $v0, $v0, $a1
	jr $ra

	
# Position = n+9*i
# Obtient l'emplacement absolue d'une colonne
# $a0 represente le numero de la colonne (compris en 0 et 8)
# $a1 represente l'offset dans la colonne (compris en 0 et 8)
# Resultat dans : $v0, position absolue de la colonne
# Registres utilises : $v0
colonne_to_case:
	mul $v0, $a1, 9
	add $v0, $v0, $a0
	jr $ra
	

# Position = (n/3)*27 + (3*n)[9] + (i/3)*6 + i[3]
# Obtient l'emplacement absolue d'un carre
# $a0 represente le numero du carre (compris en 0 et 8)
# $a1 represente l'offset dans le carre (compris en 0 et 8)
# Resultat dans : $v0, position absolue du carre
# Registres utilises : $v0
carre_to_case:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	div $t0, $a0, 3		# (n/3)*27
	mul $t0, $t0, 27
		
	div $t1, $a1, 3		# (i/3)*6
	mul $t1, $t1, 6
	add $t0, $t0, $t1
	
	move $t2, $a1
	mul $a0, $a0, 3		# (3*n)[9]
	li $a1, 9
	jal modulo
	add $t0, $t0, $v0
	
	move $a0, $t2
	li $a1, 9			# i[3]
	jal modulo
	add $v0, $t0, $v0
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra


# Range toute les cases d'une colonne dans une ligne
# $a0 represente le numero de la colonne (compris en 0 et 8)
# Registres utilises : $a1, $t3
colonne_n_to_ligne:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	la $t0, grille
	la $t2, ligne
	li $a1, 0
	boucle_get_colonne:
		bge $a1, 9, boucle_get_colonne_fin
		
		jal colonne_to_case		# Obtient l'emplacement absolu
		
		add $t1, $t0, $v0		# Stock cet element dans la ligne
		lb $t1, ($t1)
		add $t3, $t2, $a1
		sb $t1, 0($t3)
		
		add $a1, $a1, 1
		j boucle_get_colonne
	boucle_get_colonne_fin:
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra


# Range toute les cases d'un carre dans une ligne
# $a0 represente le numero du carre (compris en 0 et 8)
# Registres utilises : $a1, $t0, $t3
carre_n_to_ligne:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	la $t0, grille
	la $t2, ligne
	li $a1, 0
	boucle_get_carre:
		bge $a1, 9, boucle_get_carre_fin
		
		jal carre_to_case			# Obtient l'emplacement absolu
		
		add $t1, $t0, $v0			# Stock cet element dans la ligne
		lb $t1, ($t1)
		add $t3, $t2, $a1
		sb $t1, 0($t3)
		
		add $a1, $a1, 1
		j boucle_get_carre
	boucle_get_carre_fin:

	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	

# Obtient a partir de l'emplacement absolue le numero de la ligne
# $a0 represente l'emplacement absolue (compris entre 0 et 80)
# Resultat dans $v0
# Registre utilise: $v0
case_to_ligne:
	div $v0, $a0, 9
	jr $ra

# Obtient a partir de l'emplacement absolue le numero de la colonne
# $a0 represente l'emplacement absolue (compris entre 0 et 80)
# Resultat dans $v0
# Registre utilise: $v0
case_to_colonne:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	sub $sp, $sp, 4
	sw 	$a1, 0($sp)
	
	li $a1, 9
	jal modulo
	
	lw 	$a1, 0($sp)
	add $sp, $sp, 4
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

# Obtient a partir de l'emplacement absolue le numero du carre
# $a0 represente l'emplacement absolue (compris entre 0 et 80)
# Resultat dans $v0
# Registre utilise: $v0
case_to_carre:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	div $t0, $a0, 27		# carre = (n/27)*3 + (n[9])/3
	mul $t0, $t0, 3
	
	li $a1, 9
	jal modulo
	div $v0, $v0, 3
	
	add $v0, $v0, $t0
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
	
# Determine si les valeurs d'une ligne de 9 case ne contienne pas de redondance, les 0 sont ignorés
# $a2 represente l'adresse du debut de la ligne a tester
# Resultat dans : $v0, 1 si la ligne est valide et 0 si elle contient des redondances
# Registres utilises : $t3 ,$v0
valide:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
		
	li	$t0, 0
	li	$v0, 0
	boucle_valide_i:
		bge $t0, 9, end_valide_i 	# On parcourt tout les elements de la ligne
			add $t1, $a2, $t0
			lb	$t1, ($t1)
			beqz $t1, end_valide_j	# Si la case est vide on ne cherche pas a la comparer
			add	$t2, $t0, 1
			boucle_valide_j:
				bge $t2, 9, end_valide_j		# On parcourt tout les elements apres l'element a analyser
					add $t3, $a2, $t2
					lb	$t3, ($t3)
					beq $t1, $t3, end_valide	# S il y a un doublon dans la ligne alors il n est pas valide
					add	$t2, $t2, 1
					j boucle_valide_j
			end_valide_j:
			add	$t0, $t0, 1
		j boucle_valide_i
	end_valide_i:
	li	$v0, 1							# On a pas rencontrer de probleme donc la ligne est valide
	end_valide:
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
	
# Determine si la ligne specifiee est valide
# $a0 represente le numero de la ligne (compris en 0 et 8)
# Resultat dans : $v0, 1 si la ligne est valide, 0 sinon
# Registres utilises : $v0
ligne_n_valide:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	mul $t0, $a0, 9				# On obtient la case du debut de la ligne a tester
	
	la $a2, grille				# On teste cette ligne
	add $a2, $a2 ,$t0
	jal valide
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

	
# Determine si la colonne specifiee est valide
# $a0 represente le numero de la colonne (compris en 0 et 8)
# Resultat dans : $v0, 1 si la colonne est valide, 0 sinon
# Registres utilises : $a2, $v0
colonne_n_valide:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	
	# Les valeurs d'une colonne ne sont pas continue, on doit donc toute les ranger dans un tableau de valeur continue
	jal colonne_n_to_ligne
	
	la $a2, ligne		# On teste si ce tableau est valide
	jal valide
	
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

	
# Determine si le carre specifie est valide
# $a0 represente le numero du carre (compris en 0 et 8)
# Resultat dans : $v0, 1 si le carre est valide, 0 sinon
# Registres utilises : $a2, $v0
carre_n_valide:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	
	# Les valeurs d'un carre ne sont pas continue, on doit donc toute les ranger dans un tableau de valeur continue
	jal carre_n_to_ligne
	
	la $a2, ligne		# On teste si ce tableau est valide
	jal valide
	
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

	
# Determine si toute les lignes sont valides
# Resultat dans : $v0, 1 si toutes les colonnes sont valides, 0 sinon
# Registres utilises : $v0
lignes_valides:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	li	$t0, 0
	boucle_lignes_valides:
		bge $t0, 9, end_lignes_valides
		
		move $a0, $t0				# On test la ligne
		jal ligne_n_valide
		
		beq $v0, 0, end_lignes_valides		# Si la ligne est non valide on quitte la fonction ($v0 sera a 0)
		
		add $t0, $t0, 1
		j boucle_lignes_valides
	end_lignes_valides:
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
	
# Determine si toute les colonnes sont valides
# Resultat dans : $v0, 1 si toutes les colonnes sont valides, 0 sinon
# Registres utilises : $v0
colonnes_valides:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	li	$t0, 0
	boucle_colonnes_valides:
		bge $t0, 9, end_colonnes_valides
			
		move $a0, $t0						# Si la colonne est non valide on quitte la fonction ($v0 sera a 0)
		jal colonne_n_valide
		beq $v0, 0, end_colonnes_valides		# Si la colonne est non valide on quitte la fonction ($v0 sera a 0)
		
		add $t0, $t0, 1
		j boucle_colonnes_valides
	end_colonnes_valides:
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra


# Determine si toute les carres sont valides
# Resultat dans : $v0, 1 si toutes les carres sont valides, 0 sinon
# Registres utilises : $v0
carres_valides:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	
	li	$t0, 0							# Parcourt de 0 a 8
	boucle_carres_valides:
		bge $t0, 9, end_carres_valides
		
		move $a0, $t0							# On test le carre
		jal carre_n_valide
		beq $v0, 0, end_carres_valides			# Si le carre est non valide on quitte la fonction ($v0 sera a 0)
		
		add $t0, $t0, 1
		j boucle_carres_valides
	end_carres_valides:
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

	
# A partir d'une case, dit si la ligne la colonne et le carre auquel elle appartient sont valides
# $a0 represente l'emplacement de la case (compris entre 0 et 80)
# Valeur de retour : $v0, 1 si la ligne, colonne et carre sont valides
# Registres utilisés : $v0
case_valide:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg

	move $t0, $a0					# On obtient la ligne et on regarde si elle est valide
	jal case_to_ligne
	move $a0, $v0
	jal ligne_n_valide
	beqz $v0, case_valide_end

	move $a0, $t0					# On obtient la colonne et on regarde si elle est valide
	jal case_to_colonne
	move $a0, $v0
	jal colonne_n_valide
	beqz $v0, case_valide_end
	
	move $a0, $t0					# On obtient le carre et on regarde s'il est valide
	jal case_to_carre
	move $a0, $v0
	jal carre_n_valide
	
	case_valide_end:
	
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

	
	
# Determine si le sudoku est valide
# Valeur de retour : $v0, 1 si le sudoku est valide, 0 sinon
# Registres utilisé : $v0
sudoku_valide:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	
	jal lignes_valides				# On test toute les lignes, toute les colonnes et tout les carres et renvois 0 si l'un est faux
	beqz $v0, sudoku_valide_end
	jal carres_valides
	beqz $v0, sudoku_valide_end
	jal colonnes_valides
	beqz $v0, sudoku_valide_end
	
	li $v0, 1						# Toute les colonnes et carres sont parfais donc on met le code de retour a 1
	
	sudoku_valide_end:
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	

# Place une case dans le sudoku
# $a0 represente l'emplacement de la case (compris entre 0 et 80)
# $a1 represente le nombre de possibilités (la fonction saute les valeurs valide pour la case tant que possibilite est superieur a 1)
# Valeur de retour $v0, determine combiens de fois on a parcourut toute les possibilités
# Registre utilisé : $v0
placer_case:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg

	li $t0, 0
	la $t1, grille
	add $t1, $t1, $a0
	
	debut_placer_case:
		# Parcourt de 1 a 9
		li	$t2, 1
		boucle_placer_case:
			bge $t2, 10, end_placer_case
		
			sb $t2, 0($t1)
			jal case_valide						# On regarde si la valeur peut entrer dans la case
			
			beqz $v0, placer_case_pas_valide
				beqz $a1, case_place			# Si on a plus d'autre possibilité on place la valeur sinon on continue la boucle
					sub $a1, $a1, 1
				
			placer_case_pas_valide:
			add $t2, $t2, 1
			j boucle_placer_case
		end_placer_case:
		
		add $t0, $t0, 1							# On a parcourut une fois toute les possibilités
		j debut_placer_case
	case_place:

	move $v0, $t0

	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	


#############################################################
# Fonctions principales	

	
# Effectue la recherche des solutions du sudoku
# $a0 represente la position dans le sudoku (compris entre 0 et 81)
# $a1 represente la possibilité a tester (tant que cette valeur superieur a 0 cela veut dire qu'on veut tester d'autres possibilités)
# Resultat : $v0, 0 s'il n'y a plus de possililite, 1 s'il y en n'a encore
# Registre utilisé : $v0
recherche_algorithme:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	jal save_reg
	
	blt $a0, 81, dans_le_sudoku
		li $v0, 1
		beqz $a1, recherche_algorithme_fin		# Des possiblités n'ont pas encore ete testées
		li $v0, 0
		j recherche_algorithme_fin				# Toute les possiblités ont ete testées
	
	dans_le_sudoku:
		la $t0, grille
		add $t0, $t0, $a0
		lb $t0, 0($t0)
		beqz $t0, valeur_variable
			add $a0, $a0, 1						# Ce n'est pas une valeur variable, on passe a la suivante
			jal recherche_algorithme
			j recherche_algorithme_fin
		valeur_variable:
			jal placer_case						# On place la valeur dans la case et on passe a la suivante
			move $a1, $v0
			add $a0, $a0, 1
			jal recherche_algorithme
	
	recherche_algorithme_fin:
	jal load_reg
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
	
# Copie la grille d'origine dans la grille de test
# Registre utilisé : $t0, $t1, $t2, $t3, $t4
reset_grille:
	add $sp, $sp, -4
	sw  $ra, 0($sp)
	la $t1, original
	la $t2, grille
	li	$t0, 0
	
	boucle_reset_grille:				# On parcourt toute les valeurs et on les copies
		bge $t0, 81, end_reset_grille
			add	$t3, $t1, $t0
			lb	$t3, ($t3)
			
			add	$t4, $t2, $t0
			sb	$t3, 0($t4)
			
			add $t0, $t0, 1
		j boucle_reset_grille
	end_reset_grille:
	
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
	
# Initialise le tableau grille
# $a0 represente le nom du fichier grille
# Resultat dans : $v0
# Registres utilises : $a0, $a1, $v0
initialise_grille:
	sub $sp, $sp, 4
	sw 	$ra, 0($sp)
	
	li $a1, 0
	jal openfile							# Ouvre le fichier, quitte avec un erreur si le fichier n'existe pas
	blt $v0, 0, initialise_grille_erreur
	
	move $a0, $v0							# Recupere les valeurs du fichier et remplie la grille
	jal extractionValue
	jal closeFile
	jal changeArrayAsciiCode
	jal printArrayOriginal
	
	lw 	$ra, 0($sp)
	add $sp, $sp, 4
	li $v0, 1
	jr $ra
	initialise_grille_erreur:
		lw 	$ra, 0($sp)
		add $sp, $sp, 4
		li $v0, 0
		jr $ra
	

# Fonction principale
# Initialise la grille et execute l'algorithme de recherche
main:
	lw $a0, 4($a1)
	jal initialise_grille			# Initialise la grille
	beq $v0, 0, erreurGrille
	
	
	li $a1, 0							# Lance l'algorithme de recherche, on le lance tant qu'il y a encore des possibilités
	while_solutions:
		jal reset_grille
		li $a0, 0
		jal recherche_algorithme
		beqz $v0, end_solutions			# Si on a tout parcourut on quitte le sudoku
		
		jal sudoku_valide				# Finalement on afficher le sudoku s'il est valide (il devrait toujours l'etre a ce point)
		beqz $v0, sudoku_pas_valide
			jal printArray
		sudoku_pas_valide:
		
		add $a1, $a1, 1					# On incremente les possibilités pour trouver d'autre sudoku
		j while_solutions
	end_solutions:

	jal exit



# Quitte le programme
exit: 
	li $v0, 10
	syscall
	

# Quitte le programme avec une erreur
erreurGrille:
	la $a0, string_error
	li $v0, 4
	syscall
	li $v0, 10
	syscall
	

# End
