#!/bin/zsh

ayuda() {
  less -FERX <<- HELP
  uso: ${ZSH_ARGZERO:t} comando <query>
  herramienta para personalizar la terminal.
  comandos:
  help             mostrar esta ayuda y salir.
  tema, zsh        configurar tema del prompt.
  fuente           cambiar fuente de la terminal
  color            cambiar colores de la terminal
  descargar        descargar nuevos temas de color, desde Gogh4Termux.
  usado [estilo]   mostrar configuracion estilo
                   los estilos son los mismos comandos.
HELP
	exit "$1"
}

restaurar_mantener_cambios()
{
  if [[ -f "$modo_conf" ]]
  then
    if  [[ $(bat -p "$modo_conf") == 1 ]]
    then
      mv "${CONF_PATH}.bck"  "$CONF_PATH"
      termux-reload-settings
    else
      rm "${CONF_PATH}.bck"
    fi
  fi
}

limpieza()
{
  rm -f "$modo" 
  rm -f "$modo_conf"
}

# funciones de base

list_options() {
  find $( printf "$*" ) -maxdepth 1 -type "f,l" -print | sed -E "s/\.[^\/]+$//"
}

export DEF_LIST_OPTIONS="$( declare -f list_options )"

insert_favlist() {
  THEME_NAME="$*"

  if  [[ $(bat -p "$modo") == 1 ]]
  then
    if grep -q "$THEME_NAME" $FAVLIST 2> /dev/null
    then
        echo "change-header($prompt_ya_esta)"
    else
      echo "$THEME_NAME" >> "$FAVLIST" ; 
      sort -o "$FAVLIST" "$FAVLIST"
      echo "change-header($prompt_guardado)"
    fi
  else
    echo "execute(sed -i --follow-symlinks '\\@{}@d' $FAVLIST)+change-header($prompt_eliminado)+reload(bat -p $FAVLIST)"
  fi

}

alternar_favoritos(){ 
  if  [[ $(bat -p "$modo") == 1 ]]
  then 
    echo 0 > "$modo"
    echo "change-header($prompt_favoritas)+reload(bat -p $FAVLIST)"
  else
    echo 1 > "$modo"
    echo "change-header($prompt_global)+reload~
      $DEF_LIST_OPTIONS ; 
      list_options $DIRS ; ~" 
  fi 
}

GUARDAR_FAVORITOS="${SHORTCUT_GUARDAR_FAV}:transform| 
  $( declare -f insert_favlist ) ; 
  insert_favlist {} |"

ALTERNAR_FAVORITOS="${SHORTCUT_ALTERNAR_FAV}:transform% 
$( declare -f alternar_favoritos ) ; 
alternar_favoritos %"

ARGS_BASE=(  
  --bind "${SHORTCUT_ALTERNAR_PREVIEW}:toggle-preview"
  --bind "${ALTERNAR_FAVORITOS}"
  --bind "${GUARDAR_FAVORITOS}"
)

# funciones defecto para caso zsh|tema 

preview() {
    source $ZSH/oh-my-zsh.sh
   
    THEME_PATH=$1".zsh-theme"
    THEME_NAME="${THEME_PATH:t:r}"

    print "$fg[blue]${(l.((${COLUMNS}-${#THEME_NAME}-5))..─.)}$reset_color $THEME_NAME $fg[blue]───$reset_color"

    source "$THEME_PATH" 
  
    cols=$(tput cols)
    (exit 1)
    print -P "$PROMPT                                                                                      $RPROMPT"
}

cambiar(){
  CHOICE="$*"
  CHOICE="${CHOICE:t}"

  if sed -i --follow-symlinks\
    "s/ZSH_THEME=${ZSH_CONFIGURATION_THEME_USED}.*/ZSH_THEME=${CHOICE}/g"\
    ${CONF_PATH}; then
    if [ ! -f ${USED_FILE} ]; then

      echo -e "${CHOICE}" >> $USED_FILE

    elif [ -f $USED_FILE ]; then

      sed -i --follow-symlinks "s/${USED}/${CHOICE}/g" $USED_FILE

    fi
  fi
}


