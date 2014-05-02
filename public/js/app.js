//FOR SOMEONE GRADING WHO DOES NOT KNOW JAVASCRIPT, THIS IS IT...

$(function() {
    $('.error').hide();
    $(".commentSubmit").click(function(event) {
        // validate and process form here
        // alert(event.target.id);
        $('.error').hide();
        var entryID = event.target.id;
        var body = $("input.commentForm" + entryID).val();
        var friendID = $("input#friend_id").val();
        if (body == "") {
            $("label#body_error" + entryID).show();
            //alert("label#body_error" + entryID);
            //alert(body);
            $("#commentInput" + entryID).addClass("has-error");
            $("input#" + entryID).focus();
            return false;
        }
        $("#commentInput" + entryID).removeClass("has-error");

        $("#loading" + entryID).html("<img src='/pics/loading.gif'>");
        var dataString = 'body='+ body + '&entry_id=' + entryID + '&friend_id=' + friendID;
//alert (dataString);return false;
        $.ajax({
            type: "POST",
            url: "/entry/"+ entryID + "/comment/create",
            data: dataString,
            success: function(html) {
                html = $(html);
                setTimeout(function (){
                    $("#loading" + entryID).empty();
                    console.log(entryID);
                    $("input#a" + entryID).val("");
                    //$('#commentForm').before(html).fadeIn('slow');
                    (html).hide().prependTo('#commentEntries' + entryID).slideDown("slow");
                }, 1000);
                console.log(html);
                (html).find(".commentDelete").click(function(event) {
                    console.log('clicked');
                    commentDelete(event, entryID);

                });

            }
        });
        return false;

    });
    $(".commentDelete").click(function(event) {
        var entryID = $('.entry_id').attr('id');
        var commentID = event.target.id;
        var dataString = 'entry_id='+ entryID + '&id=' + commentID;

        $("#loadingDelete" + commentID).html("<img src='/pics/loading.gif'>");

        $.ajax({
            type: "POST",
            url: "/entry/"+ entryID + "/comment/"+ commentID + "/delete",
            data: dataString,
            success: function(html) {
                setTimeout(function (){
                    $("#loadingDelete" + commentID).empty();
                    $("input#" + entryID).val("");
                    //$('#commentForm').before(html).fadeIn('slow');
                    $("#" + html).slideUp("slow");

                }, 1000);


            }
        });
        return false;


    });


    $(".entryDelete").click(function(event) {
        var entryID = event.target.id;
        var dataString = 'id='+ entryID;

        $("#loadingEntries" + entryID).html("<img src='/pics/loading.gif'>");

        $.ajax({
            type: "POST",
            url: "/entry/"+ entryID + "/delete",
            data: dataString,
            success: function(html) {

                setTimeout(function (){
                    $("#loadingEntries").empty();
                    //$('#commentForm').before(html).fadeIn('slow');
                    $("#" + html).slideUp("slow");
                    setTimeout(function (){

                        $("#" + html).remove();
                    num = $('.entries').length;
                    console.log(num);
                    if (num == 0) {
                        $("#post-container").fadeOut('fast');
                        $("#post-container").hide();
                        $("#noPosts").removeClass("hide");
                        $("#noPosts").hide();
                        $("#noPosts").fadeIn('slow');




                    }
                }, 1050);
                }, 1000);



            }
        });
        return false;


    });
    function commentDelete (event, entryID) {
        var entryID = entryID;
        var commentID = event.target.id;
        console.log('hello');
        console.log(commentID);

        var dataString = 'entry_id='+ entryID + '&id=' + commentID;

        $("#loadingDelete" + commentID).html("<img src='/pics/loading.gif'>");

        $.ajax({
            type: "POST",
            url: "/entry/"+ entryID + "/comment/"+ commentID + "/delete",
            data: dataString,
            success: function(html) {
                setTimeout(function (){
                    $("#loadingDelete" + commentID).empty();
                    $("input#" + entryID).val("");
                    //$('#commentForm').before(html).fadeIn('slow');
                    $("#" + html).slideUp("slow");;
                }, 1000);


            }
        });


    }


    $("#entrySubmit").click(function(event) {
        // validate and process form here
        // alert(event.target.id);
        $('.error').hide();
        var subject = $("input#subject").val();
        if (subject == "") {
            $("label#subject_error").show();
            //alert("label#body_error" + entryID);
            //alert(body);
            $("#subjectInput").addClass("has-error");
            //$("label#subject_error").after("<br /><br />");
            $("input#subject").focus();
            return false;
        }

    });

    $(".friendUser").click(function(event) {
        console.log('hii');
        var userID = event.target.id;
        $("#" + userID + ".friendUser").html("Loading...");
        $("#" + userID + ".friendUser").removeClass("btn btn-primary");
        $("#" + userID + ".friendUser").addClass("btn btn-default disabled");
        var dataString = 'friend_id='+ userID;
        $.ajax({
            type: "POST",
            url: "/friend",
            data: dataString,
            success: function(html) {
                console.log('hello');
                setTimeout(function (){
                    $("#" + userID + ".friendUser").html("Request Pending");



                    //$('#commentForm').before(html).fadeIn('slow');
                }, 1000);


            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
                $("#" + userID).html("Friend");
                $("#" + userID).addClass("btn btn-primary");
                $("#" + userID).removeClass("btn btn-default disabled");
                alert("Error submitting friend request.");
            }
        });
        return false;




    });
});



